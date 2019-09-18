require "uri"
require "http/params"
require "http/client"
require "http/web_socket"
require "json"

require "./logger.cr"
require "./ari/*"
require "./ari/resources/*"
require "./ari/models/*"
require "./ari/events/*"

module Asterisk
  class ARI
    include Callbacks

    property logger : Logger = ::Asterisk.logger

    # ARI app-name
    getter app : String

    # will be set by `connect`
    getter asterisk_version : String?
    getter entity_id        : String?

    @url : String
    @uri : URI

    @username  : String
    @password  : String

    private getter! ws : HTTP::WebSocket?

    @conn_lock = Mutex.new
    @client : HTTP::Client?
    def client
      @conn_lock.synchronize do
        @client.as(HTTP::Client)
      end
    end

    {% for method in %w(get post put delete) %}
      def {{method.id}}(path, headers : HTTP::Headers? = nil, body : HTTP::Client::BodyType = nil) : HTTP::Client::Response
        client.{{method.id}}("#{@uri.path}/#{path}", headers, body)
      end
    {% end %}

    class AuthenticationError < Exception
    end

    class ConnectionError < Exception
    end

    def initialize(@url = "http://127.0.0.1:8088/ari", @app = "asterisk.cr", @username = "", @password = "")
      @uri = URI.parse(@url)
    end

    def start
      connect

      ws.on_close do
        client.close
      end

      ws.on_message do |message|
        message_json = JSON.parse(message)
        event = message_json["type"].as_s
        klass = __events[event]
        event_data = klass.from_json(message)

        # user-defined callbacks
        # find_callback?(message_json).try &.call(self, event_data)
        find_callback?(message_json).try &.call(self, message)

        # Macro code that generate case ... when ... end block for ARI events
        {% begin %}
          case event
          {% for t in Events.constants %}
            {% event_name = t.stringify %}
            {% unless %w(Message Event).includes?(event_name) %}
              {% klass = ("Events::" + t.stringify).id %}
              when {{event_name}}
                @on_{{event_name.underscore.id}}.try &.call(self, event_data.as({{klass}}))
              {% end %}
          {% end %}
            else
            raise "Don't know this event: #{event}"
          end
        {% end %}
      end

      spawn do
        ws.run
      end
    end

    # List of ARI events as a hash (event_name => EventName)
    private def __events
      {% begin %}
        {% events = {} of String => Class %}
        {% Events.constants.map do |klass|
          klass_name = klass.stringify
          unless %w(Message Event).includes?(klass_name)
            events[klass_name] = ("Events::" + klass.stringify).id
          end
        end %}
        {{events}}
      {% end %}
    end

    # @event_callbacks = Hash(JSON::Any, Proc(ARI, Events::Event, Nil)).new
    @event_callbacks = Hash(JSON::Any, Proc(ARI, String, Nil)).new

    # def on_event(filter : JSON::Any, &block : ARI, Events::Event ->)
    def on(filter : JSON::Any, &block : ARI, String ->)
      @event_callbacks[filter] = block
    end

    def remove_filter(filter : JSON::Any)
      @event_callbacks.delete(filter)
    end

    private def find_callback?(message : JSON::Any)
      @event_callbacks.map do |filter, block|
        if json_includes?(message, filter)
          return @event_callbacks[filter]
        end
      end
      nil
    end

    # https://play.crystal-lang.org/#/r/7lam
    # https://play.crystal-lang.org/#/r/7lb5
    private def json_includes?(message : JSON::Any, filter : JSON::Any)
      return false unless filter.as_h?
      return false if filter.as_h.empty?

      result = filter.as_h.map { |key, filter|
        if message[key]?
          if filter.as_s?
            message[key] == filter
          elsif filter.as_h? && message[key].as_h?
            json_includes?(message[key], filter)
          else
            false
          end
        else
          false
        end
      }

      ! result.includes?(false)
    end

    macro resources
      {% for t in Resources.all_subclasses %}
        {% klass = t.stringify.split("::").last.id %}
        {% resource = klass.stringify.underscore.id %}
        @{{resource}} : {{klass}}? = nil
        def {{resource}}
          @{{resource}} ||= {{klass}}.new(client: self)
        end
      {% end %}
      end
    resources

    private def connect
      raise ConnectionError.new("Already connected") if ws? && ! ws.closed?

      @client = HTTP::Client.new(@uri)
      client.basic_auth(@username, @password)

      # connect to the HTTP(s) interface and get asterisk version
      info = JSON.parse(get("asterisk/info").body.to_s)
      if info["message"]?.to_s =~ /Authentication required/i
        raise AuthenticationError.new(info["message"].to_s)
      end

      # Execute connection to the Asterisk API and set
      # asterisk_version and entity_id
      @asterisk_version = info["system"]["version"].to_s
      @entity_id        = info["system"]["entity_id"].to_s # mac-address

      # Connect to the WS/WSS.
      # ARI events will be received through on_message callback
      query_params = HTTP::Params.encode({"api_key" => "#{@username}:#{@password}", "app" => @app}).to_s
      @ws = HTTP::WebSocket.new("#{@url}/events?#{query_params}")
      raise ConnectionError.new("Can't connect to the #{@url}") if ws.closed?

      # Host is down, wrong port etc
      # Error connecting to '127.0.0.1:8088': Connection refused (Errno)
      # Wrong credentials
      # Handshake got denied. Status code was 401. (Socket::Error)
    end

    def close
      client.close
      ws.close unless closed?
    end

    def closed?
      ws.closed?
    end
  end
end
