require "uri"
require "http/params"
require "http/client"
require "http/web_socket"
require "json"

module Asterisk
  class ARI
    getter logger : Logger = Asterisk.logger
    getter app : String

    getter app : String
    getter url : String
    getter uri : URI
    @username  : String
    @password  : String
    getter asterisk_version : String?
    getter entity_id        : String?

    @ws  : HTTP::WebSocket?

    getter api : HTTP::Client
    {% for method in %w(get post put delete) %}
      def {{method.id}}(path, headers : HTTP::Headers? = nil, body : HTTP::Client::BodyType = nil) : HTTP::Client::Response
        api.{{method.id}}("#{uri.path}/#{path}", headers, body)
      end
    {% end %}

    class AuthenticationError < Exception
    end

    def initialize(@url = "http://127.0.0.1:8088/ari", @app = "asterisk.cr", @username = "", @password = "")
      @uri = URI.parse(@url)
      @api = HTTP::Client.new(uri)
      @api.basic_auth(@username, @password)
    end

    def connect
      # connect to the HTTP(s) interface and get asterisk version
      info = JSON.parse(get("asterisk/info").body.to_s)
      if info["message"]?.to_s =~ /Authentication required/i
        raise AuthenticationError.new(info["message"].to_s)
      end

      @asterisk_version = info["system"]["version"].to_s
      @entity_id        = info["system"]["entity_id"].to_s

      # Connect to the WS/WSS.
      # ARI events will be received through on_message callback
      query_params = HTTP::Params.encode({"api_key" => "#{@username}:#{@password}", "app" => @app}).to_s
      @ws = HTTP::WebSocket.new("#{@url}/events?#{query_params}")

      # Host is down, wrong port etc
      # Error connecting to '127.0.0.1:8088': Connection refused (Errno)
      # Wrong credentials
      # Handshake got denied. Status code was 401. (Socket::Error)
    end

    def start
      connect
      # @ws.as(HTTP::WebSocket).on_close do
      #   # cleanup data
      # end

      # @channel_message = Channel(String).new
      @ws.as(HTTP::WebSocket).on_message do |message|
        # @channel_message.send message
        message = JSON.parse(message)
        # logger.debug "#{self.class}.on_message: #{message.pretty_inspect}\n---"
        puts "#{self.class}.on_message:\n#{message.pretty_inspect}\n---"
      end

      spawn do
        @ws.as(HTTP::WebSocket).run
      end
    end

    def close
      @api.close
      @ws.close
    end
  end
end
