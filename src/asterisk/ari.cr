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
    class AuthenticationError < Exception
    end

    class ConnectionError < Exception
    end

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

    def initialize(@url = "http://127.0.0.1:8088/ari", @app = "asterisk.cr", @username = "", @password = "")
      @uri = URI.parse(@url)
    end

    def start
      if connected?
        logger.info "#{self.class}: Already started"
        return
      end

      connect

      ws.on_close do
        close
      end

      ws.on_message do |message|
        message_json = JSON.parse(message)

        event = message_json["type"]?
        if event.nil?
          logger.error "WS message does not look like Asterisk ARI:\n#{message}\n---"
          next
        end
        event = event.as_s

        # user-defined handlers, these receive event as a JSON message, because
        # with generic filtering, multipe types could pass `find_handlers`
        find_handlers(message_json).each do |handler|
          spawn do
            handler.call(message)
          end
        end

        klass = @events_map[event]?
        if klass.nil?
          logger.error "Don't know this event: #{event}"
          next
        end

        event_data = klass.from_json(message)

        # Macro code that generate case ... when ... end block for ARI events
        {% begin %}
          case event
          {% for t in Events.constants %}
            {% event_name = t.stringify %}
            {% klass = ("Events::" + t.stringify).id %}
            {% unless %w(Message Event).includes?(event_name) %}
            when {{event_name}}
              @{{event_name.underscore.id}}_handlers.each do |handler_id, handler|
                logger.error "Executing handler #{handler_id} of {{event_name.id}}"
                spawn do
                  handler.call(event_data.as({{klass}}))
                end
              end
            {% end %}
          {% end %}
          end
        {% end %}
      end

      spawn do
        ws.run
      end
    end

    # Map of ARI events as a hash (event_name => EventName)
    {% begin %}
      {% events = {} of String => Class %}
      {% Events.constants.map do |klass|
        klass_name = klass.stringify
        unless %w(Message Event).includes?(klass_name)
          events[klass_name] = ("Events::" + klass.stringify).id
        end
      end %}
      @events_map = {{events}}
    {% end %}

    # Generates events handlers for known events, like this:
    # ```
    # def on_device_state_changed(&@on_device_state_changed : Events::DeviceStateChanged ->)
    # end
    # ```
    {% begin %}
      {% for t in Events.constants %}
        {% event_name = t.stringify %}
        {% unless %w(Message Event).includes?(event_name) %}
          {% klass = ("Events::" + event_name).id %}
          {% event_name = event_name.underscore.id %}
          @{{event_name}}_handlers = Hash(String, Proc({{klass}}, Nil)).new

          def on_{{event_name}}(&block : {{klass}} ->)
            handler_id = UUID.random.to_s
            @{{event_name}}_handlers[handler_id] = block
            handler_id
          end

          def on_{{event_name}}(handler_id : String, &block : {{klass}} ->)
            @{{event_name}}_handlers[handler_id] = block
            handler_id
          end
        {% end %}
      {% end %}
    {% end %}

    @handlers = Hash(String, Hash(JSON::Any, Proc(String, Nil))).new

    def on(event_filter : JSON::Any, &block : String ->) : String
      handler_id = UUID.random.to_s
      @handlers[handler_id] = { event_filter => block }
      handler_id
    end

    def on_(handler_id : String, event_filter : JSON::Any, &block : String ->) : String
      @handlers[handler_id] = { event_filter => block }
      handler_id
    end

    def remove_handler(handler_id : String)
      @handlers.delete(handler_id)
    end

    private def find_handlers(message : JSON::Any)
      @handlers.map { |_, handler|
        handler.map { |event_filter, _|
          handler[event_filter] if json_includes?(message, event_filter)
        }
      }.flatten.compact
    end

    # Match JSON::Any message against JSON::Any event_filter. event_filter should be
    # a Hash of Strings or Hash of Hashes of Strings.
    #
    # https://play.crystal-lang.org/#/r/7lam
    # https://play.crystal-lang.org/#/r/7lb5
    private def json_includes?(message : JSON::Any, event_filter : JSON::Any)
      return false unless event_filter.as_h?
      return false if event_filter.as_h.empty?

      result = event_filter.as_h.map { |key, event_filter|
        if message[key]?
          if event_filter.as_s?
            message[key] == event_filter
          elsif event_filter.as_h? && message[key].as_h?
            json_includes?(message[key], event_filter)
          else
            false
          end
        else
          false
        end
      }

      !result.includes?(false)
    end

    macro resources
      {% for t in Resources.all_subclasses %}
        {% klass = t.stringify.split("::").last.id %}
        {% resource = klass.stringify.underscore.id %}
        @{{resource}} : {{klass}}? = nil
        def {{resource}}
          @{{resource}} ||= {{klass}}.new(ari: self)
        end
      {% end %}
      end
    resources

    private def connect
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

    def connected?
      ws? && ! ws.closed?
    end

    def closed?
      ws.nil? || (ws? && ws.closed?)
    end
  end
end
