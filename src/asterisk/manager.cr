require "socket"
require "time"
require "secure_random"

module Asterisk
  class Manager
    class LoginError < Exception
    end

    class ConnectionLostError < Exception
    end

    def logger
      Asterisk.logger
    end

    def initialize(@host = "127.0.0.1", @port = "5038")
      @conn = TCPSocket.new
      @should_reconnect = true
      @connected = false

      @actions = Hash(String, Channel(Bool)).new
      @event_map = Hash(String, Array(Hash(String, String))).new
    end

    def connect!
      @conn = TCPSocket.new(@host, @port, 10, 10)
      @conn.tcp_keepalive_interval = 10
      @conn.tcp_keepalive_idle = 5
      @conn.tcp_keepalive_count = 5
      @conn.keepalive = true
      @conn.read_timeout = 5

      login
      event_loop if connected?
    end

    def disconnect!
      if connected?
        res = send_action( { "action" => "logoff" } )
        logger.info res
      end
    ensure
      @conn.close rescue nil
      @connected = false
      logger.debug "Disconnected!"
    end

    def login
      send_action!( { "action" => "login", "username" => "ahn", "secret" => "ahn" } )
      login_event = receive_event
      if login_event
        # logger.debug login_event
        if login_event["response"].downcase == "success"
          # FullyBooted should follow after login
          fully_booted_event = receive_event
          if fully_booted_event && fully_booted_event["event"] == "FullyBooted"
            @connected = true
            logger.debug "Connected!"
          else
            disconnect!
          end
        else
          logger.error "Login failed: #{login_event["message"]}"
        end
      else
        logger.error "Login failed (AMI timeout or wrong address, or Asterisk is off - also check manager.conf)"
      end
    end

    def connected?
      @connected
    end

    def should_reconnect?
      @should_reconnect
    end

    def send_action(action)
      raise LoginError.new("action should present") unless action.has_key?("action")
      raise LoginError.new("AMI should be in connected state to send action") unless connected?

      # actionid is maindatory in order to track action response
      actionid = action["actionid"] ||= SecureRandom.uuid

      # register response catcher - some responses are set of multiple events,
      # have to track all of them
      response_catcher actionid

      send_action! action

      catch_response actionid
    end

    private def send_action!(action)
      multiline_string = ""
      action.each do |k,v|
        multiline_string += "#{k}: #{v}\r\n"
      end
      multiline_string += "\r\n"

      @conn << multiline_string
    end

    private def response_catcher(actionid : String)
      @actions[actionid] = Channel(Bool).new
    end

    private def catch_response(actionid : String)
      @actions[actionid].receive
      @event_map.delete(actionid)
    end

    private def event_loop
      spawn do
        loop do
          while connected?
            process_single_event
          end

          if should_reconnect?
            reconnect!
          else
            break
          end
        end
      end
    end

    def reconnect!
      logger.info "Reconnecting!"
      disconnect!
      sleep 0.25
      connect!
    rescue
      nil
    end

    private def process_single_event
      # receive event or nil in case of timeout
      event = begin
                receive_event
              rescue ConnectionLostError
                nil
              end

      if event
        logger.debug "EVENT: #{event}"

        if event.has_key?("actionid")
          actionid = event["actionid"]

          if event.has_key?("eventlist")
            if event["eventlist"].downcase == "start"
              # {"response" => "Success", "actionid" => "bd55ec79-1781-4ca1-9ef8-8c6abe491f99", "eventlist" => "start", "message" => "Peer status list will follow"}
              @event_map[actionid] ||= Array(Hash(String, String)).new
            else
              # {"event" => "PeerlistComplete", "actionid" => "bd55ec79-1781-4ca1-9ef8-8c6abe491f99", "eventlist" => "Complete", "listitems" => "1"}
              @actions[actionid].send true
            end
          else
            if @event_map.has_key?(actionid)
              @event_map[actionid].push(event)
            else
              @event_map[actionid] = Array(Hash(String, String)).new
              @event_map[actionid].push(event)
              @actions[actionid].send true
            end
          end
        else
          # callbacks and hooks
        end
      end
    end

    # Asterisk manager event is a set of multiple strings with "\r\n" at the end and
    # empty string ("\r\n") terminating event data
    private def receive_event
      event = @conn.gets("\r\n\r\n").to_s.gsub("\r\n\r\n", "")
      logger.debug "Received Asterisk manager event: #{event}"
      event = event.split("\r\n")

      if event == [""]
        # AMI just disconnected, if empty line was received
        @connected = false
        raise ConnectionLostError.new("AMI connection lost")
      else
        parse_event event
      end

    rescue IO::Timeout
      # Unstable connection, causing no event or broken event
      nil
    end

    # parse_event process multi-line array. Normally Asterisk manager event do hold key: value
    # delimited by ':', however there could be an message without delimiter, it will be assigned to the unknown key
    private def parse_event(event : Array)
      result = {} of String => String
      if event.empty?
        nil
      else
        event.each do |line|
          # logger.debug "Processing line: #{line}"
          if /^(.*):(.*)$/ =~ line
            result[$1.to_s.downcase] = $2.to_s.strip
          else
            result["unknown"] ||= ""
            result["unknown"] += line
          end
        end

        result
      end
    end
  end
end
