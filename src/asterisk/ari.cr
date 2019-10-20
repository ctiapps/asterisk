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

    GRACEFULLY_HANDLERS_REMOVAL_TIMEOUT = 0.02.seconds

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

    # HTTP client connection lock
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

    # Start ARI connections (HTTP client, WS-client and event handlers)
    # TODO: client handlers for on_connected and on_close
    def start
      if connected?
        logger.info "#{self.class}: Already started"
        return
      end

      connect

      ws.on_close do
        close
      end

      ws.on_message do |json_data|
        process_ws_message json_data
      end

      # Remove orphaned event handlers after expiration
      on_recording_finished do |event|
        event_filter = JSON.parse(%({"recording": {"name": "#{event.recording.name}"}}))
        sleep GRACEFULLY_HANDLERS_REMOVAL_TIMEOUT
        handlers(event_filter).keys.each { |handler_id| remove_handler(handler_id) }
      end

      on_recording_failed do |event|
        event_filter = JSON.parse(%({"recording": {"name": "#{event.recording.name}"}}))
        sleep GRACEFULLY_HANDLERS_REMOVAL_TIMEOUT
        handlers(event_filter).keys.each { |handler_id| remove_handler(handler_id) }
      end

      on_playback_finished do |event|
        event_filter = JSON.parse(%({"playback": {"id": "#{event.playback.id}"}}))
        sleep GRACEFULLY_HANDLERS_REMOVAL_TIMEOUT
        handlers(event_filter).keys.each { |handler_id| remove_handler(handler_id) }
      end

      on_bridge_destroyed do |event|
        event_filter = JSON.parse(%({"bridge": {"id": "#{event.bridge.id}"}}))
        sleep GRACEFULLY_HANDLERS_REMOVAL_TIMEOUT
        handlers(event_filter).keys.each { |handler_id| remove_handler(handler_id) }
      end

      on_stasis_end do |event|
        event_filter = JSON.parse(%({"channel": {"id": "#{event.channel.id}"}}))
        sleep GRACEFULLY_HANDLERS_REMOVAL_TIMEOUT
        handlers(event_filter).keys.each { |handler_id| remove_handler(handler_id) }
      end

      spawn do
        ws.run
      end
    end

    private def connect
      @client = HTTP::Client.new(@uri)
      client.basic_auth(@username, @password)

      # connect to the HTTP(s) interface and get asterisk version
      info = JSON.parse(get("asterisk/info").body.to_s)
      if info["message"]?.to_s =~ /Authentication required/i
        raise AuthenticationError.new(info["message"].to_s)
      end

      # Execute connection to the Asterisk API and set
      # `asterisk_version` and `entity_id`
      @asterisk_version = info["system"]["version"].to_s
      # mac-address
      @entity_id = info["system"]["entity_id"].to_s

      # Connect to the WS/WSS.
      # ARI events will be received through on_message callback
      query_params = HTTP::Params.encode({"api_key" => "#{@username}:#{@password}", "app" => @app}).to_s
      @ws = HTTP::WebSocket.new("#{@url}/events?#{query_params}")
      raise ConnectionError.new("Can't connect to the #{@url}") if ws.closed?

      # TODO:
      # Host is down, wrong port etc
      # Error connecting to '127.0.0.1:8088': Connection refused (Errno)
      # Wrong credentials
      # Handshake got denied. Status code was 401. (Socket::Error)
    end

    # close ARI http and ws-connections
    def close
      handlers.clear
      client.close
      ws.close unless closed?
    end

    def connected?
      ws? && ! ws.closed?
    end

    def closed?
      ws.nil? || (ws? && ws.closed?)
    end

    # Include ARI resources with ARI instance, so once ARI conenction get
    # created, resources are available within it, i.e.:
    # ```
    # ari.channels.answer channel_id: event.channel.id
    # ```
    {% begin %}
      {% for t in Resources.all_subclasses %}
        {% klass = t.stringify.split("::").last.id %}
        {% resource = klass.stringify.underscore.id %}
        @{{resource}} : {{klass}}? = nil

        def {{resource}}
          @{{resource}} ||= {{klass}}.new(ari: self)
        end
      {% end %}
    {% end %}

    # Map of ARI events as a hash (event_name => EventName)
    {% begin %}
      {%
        events = {} of String => Class

        Events.constants.map do |klass|
          klass_name = klass.stringify
          unless %w(Message Event).includes?(klass_name)
            events[klass_name] = ("Events::" + klass.stringify).id
          end
        end
      %}
      @events_map = {{events}}
    {% end %}

    private def process_ws_message(json_data)
      event = JSON.parse(json_data)

      # Basic validation of the ws message.
      # ARI event is a hash-like structure with field `type` at the root,
      # containing string (ARI event name)
      unless event.as_h?.try &.["type"]?.try &.as_s?
        logger.error "Message does not look like Asterisk ARI event:\n#{json_data}\n---"
        return
      end

      # find registered for event handlers and execute them
      event_handlers(event).each do |handler|
        spawn do
          handler.call(json_data)
        end
      end
    end

    @handlers = Hash(String, Hash(JSON::Any, Proc(String, Nil))).new

    def event_on(event_filter : JSON::Any, &block : String ->) : String
      handler_id = UUID.random.to_s
      @handlers[handler_id] = { event_filter => block }
      handler_id
    end

    def event_on(handler_id : String, event_filter : JSON::Any, &block : String ->) : String
      @handlers[handler_id] = { event_filter => block }
      handler_id
    end

    def event_on(event_filter : NamedTuple, &block : String ->) : String
      event_filter = JSON.parse(event_filter.to_json)
      handler_id = UUID.random.to_s
      @handlers[handler_id] = { event_filter => block }
      handler_id
    end

    def event_on(handler_id : String, event_filter : NamedTuple, &block : String ->) : String
      event_filter = JSON.parse(event_filter.to_json)
      @handlers[handler_id] = { event_filter => block }
      handler_id
    end

    def remove_handler(handler_id : String)
      @handlers.delete(handler_id)
    end

    # Returns array of event handlers based on `event_filter` for given `event`
    private def event_handlers(event : JSON::Any)
      @handlers.map { |_, handler|
        handler.map { |event_filter, _|
          handler[event_filter] if json_includes?(event, event_filter)
        }
      }.flatten.compact
    end

    def handlers(event_filter : JSON::Any = JSON.parse("{}"))
      return @handlers if event_filter.as_h?.try &.empty?

      h = @handlers.map { |handler_id, handler|
        handler.map { |handler_event_filter, _|
          if json_includes?(handler_event_filter, event_filter)
            { handler_id => handler }
          end
        }
      }.flatten.compact

      if h.empty?
        Hash(String, Hash(JSON::Any, Proc(String, Nil))).new
      else
        h.flatten.compact.reduce { |memo, record| memo.merge(record) }
      end
    end

    # Match `event` against `event_filter`, both must be `JSON::Any` objects.
    # `event_filter` should be a Hash of Strings or Hash of Hashes of Strings.
    #
    # https://play.crystal-lang.org/#/r/7lam
    # https://play.crystal-lang.org/#/r/7lb5
    private def json_includes?(event : JSON::Any, event_filter : JSON::Any)
      return false unless event_filter.as_h?
      return false if event_filter.as_h.empty?

      result = event_filter.as_h.map { |key, ef|
        if event[key]?
          if ef.as_s?
            event[key] == ef
          elsif ef.as_h? && event[key].as_h?
            json_includes?(event[key], ef)
          else
            false
          end
        else
          false
        end
      }

      !result.includes?(false)
    end

    # Generates events handlers for known ARI events:
    # ```
    # def on_device_state_changed(event_filter : JSON::Any = JSON.parse("{}"), &block : Events::DeviceStateChanged ->)
    #   # set filter on `type`
    #   event_filter.as_h["type"] = JSON.parse(%("DeviceStateChanged"))
    #   event_on(event_filter) do |json_data|
    #     event_data = {{klass}}.from_json(json_data)
    #     block.call(event_data)
    #   end
    # end
    # ```
    #
    # and exactly same but with user-created `handler_id`:
    # ```
    # def on_device_state_changed(handler_id : String, event_filter : JSON::Any = JSON.parse("{}"), &block : Events::DeviceStateChanged ->)
    #   # ...
    # end
    # ```
    #
    # Usage example:
    # ```
    # handler_id = ari.on_stasis_start do |event|
    #   ari.channels.answer channel_id: event.channel.id
    #   # ...
    # end
    # # ...
    # ari.remove_handler(handler_id)
    # ```
    {% begin %}
      {% for t in Events.constants %}
        {% event = t.stringify %}
        {% unless %w(Message Event).includes?(event) %}
          {% klass = ("Events::" + event).id %}
          {% method = event.underscore.id %}
          {% event = event.id %}

          def on_{{method}}(event_filter : JSON::Any = JSON.parse("{}"), &block : {{klass}} ->)
           # set filter on `type`
            event_filter.as_h["type"] = JSON.parse(%("{{event}}"))
            event_on(event_filter) do |json_data|
              event_data = {{klass}}.from_json(json_data)
              block.call(event_data)
            end
          end

          def on_{{method}}(event_filter : NamedTuple, &block : {{klass}} ->)
            event_filter = JSON.parse((event_filter.merge type: "{{event}}").to_json)
            event_on(event_filter) do |json_data|
              event_data = {{klass}}.from_json(json_data)
              block.call(event_data)
            end
          end

          def on_{{method}}(handler_id : String, event_filter : JSON::Any = JSON.parse("{}"), &block : {{klass}} ->)
            # set filter on `type`
            event_filter.as_h["type"] = JSON.parse(%("{{event}}"))
            event_on(handler_id, event_filter) do |json_data|
              event_data = {{klass}}.from_json(json_data)
              block.call(event_data)
            end
          end

          def on_{{method}}(handler_id : String, event_filter : NamedTuple, &block : {{klass}} ->)
            # set filter on `type`
            event_filter = JSON.parse((event_filter.merge type: "{{event}}").to_json)
            event_on(handler_id, event_filter) do |json_data|
              event_data = {{klass}}.from_json(json_data)
              block.call(event_data)
            end
          end

        {% end %}
      {% end %}
    {% end %}
  end
end
