require "socket"
require "time"
require "secure_random"

module Asterisk
  class Manager
    def initialize
      @conn = TCPSocket.new("127.0.0.1", 5038, 10, 10)
      @conn.tcp_keepalive_interval = 10
      @conn.tcp_keepalive_idle = 2
      @conn.tcp_keepalive_count = 5
      @conn.keepalive = true
      # @conn.read_timeout = 2

      @connected = false

      @actions = Hash(String, Channel(Bool)).new
      @event_map = Hash(String, Array(Hash(String, String))).new
    end

    def connect
      login
      puts "connected!" if connected?
    end

    def disconnect
      if @conn && connected?
        @conn.close
        @connected = false
        puts "disconnected!"
      end
    end

    def login
      send_action!( { "action" => "login", "username" => "ahn", "secret" => "ahn" } )
      login_event = receive_event
      if login_event
        puts login_event
        if login_event["response"] == "Success"
          @connected = true
          listen!
        else
          puts "Login failed: #{login_event["message"]}"
        end
      else
        puts "Login failed (AMI timeout or wrong address, or Asterisk is off - also check manager.conf)"
      end
    end

    def connected?
      @connected == true
    end

    def send_action(action)
      raise LoginError.new("action should present") unless action.has_key?("action")
      raise LoginError.new("AMI should be in connected state to send action") unless connected?

      actionid = action["actionid"] ||= SecureRandom.uuid
      response_catcher actionid

      send_action! action

      catch_response actionid
    end

    private def send_action!(action)
      action.each do |k,v|
        @conn << "#{k}: #{v}\r\n"
      end

      @conn << "\r\n"
    end

    private def response_catcher(actionid : String)
      @actions[actionid] = Channel(Bool).new
    end

    private def catch_response(actionid : String)
      @actions[actionid].receive
      @event_map.delete(actionid)
    end

    # terminate block.call after given timeout
    private def timeout(terminate_after : Float64, &block)
      ch = Channel(Bool).new

      spawn do
        sleep terminate_after
        ch.close
      end

      spawn do
        block.call
        ch.send true
      end

      res = ch.receive rescue false
    end

    private def listen!
      spawn do
        while connected?
          event = receive_event

          if event
            puts "EVENT: #{event}"

            if event.has_key?("actionid")
              actionid = event["actionid"]

              if event.has_key?("eventlist")
                if event["eventlist"] == "start"
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
      end
    end

    private def receive_event
      event = [] of String

      timeout(10.0) do
        loop do
          next_line = @conn.gets rescue ""
          break if next_line.to_s.empty?
          if next_line
            event.push next_line
          end
        end
      end

      parse_event event
    end

    private def parse_event(event : Array)
      result = {} of String => String
      if event.empty?
        nil
      else
        event.each do |line|
          # puts "Processing line: #{line}."
          if /^(.*):(.*)$/ =~ line
            result[$1.to_s.downcase] = $2.to_s.strip
          else
            result["unknown"] = line
          end
        end

        result
      end
    end
  end
end
