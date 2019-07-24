require "./logger.cr"
require "socket"
require "time"
require "uuid"

module Asterisk
  class AMI
    @logger : Logger = Asterisk.logger
    getter logger

    @conn = TCPSocket.new
    @running = false
    @fully_booted = false

    alias AMIData = Hash(String, String | Nil)
    @tracked_event = Channel::Unbuffered(String).new
    @event_channel : Channel::Unbuffered(AMIData)?

    class LoginError < Exception
    end

    class NotBootedError < Exception
    end

    class ConnectionError < Exception
    end

    def initialize(@host = "127.0.0.1", @port = "5038", @username = "", @secret = "", @logger : Logger = Asterisk.logger)
    end

    def login
      @conn = TCPSocket.new(@host, @port)
      listen
      @conn.keepalive = true
      response = send_action({"action" => "Login", "username" => @username, "secret" => @secret})
      logger.debug "#{self.class}.login response: #{response}"
      if response["response"] == "Success"
        # running but FullyBooted event shall be also processed
        sleep 0.03
        unless fully_booted?
          disconnect_and_raise NotBootedError.new("Asterisk did not respond with FullyBooted event")
        end
      else
        disconnect_and_raise LoginError.new(response["message"])
      end
    end

    private def disconnect_and_raise(ex : Exception)
      # close everything and raise error
      logoff!
    ensure
      raise ex
    end

    def connected?
      running? && fully_booted?
    end

    private def running?
      @running
    end

    private def running!
      @running = true
    end

    private def fully_booted?
      @fully_booted
    end

    private def fully_booted!
      @fully_booted = true
    end

    def logoff
      logger.debug "#{self.class}.logoff: Will logoff"
      if running?
        logger.debug "#{self.class}.logoff: Will logoff"
        response = send_action({"action" => "Logoff"})
        # {"response" => "Goodbye", "message" => "Thanks for all the fish."}
        if response["response"] == "Goodbye"
          logger.debug "#{self.class}.logoff: Logged off"
        else
          logger.error "#{self.class}.logoff: Logged off with incorrect response: #{response}"
        end
      end
    ensure
      logoff!
    end

    private def logoff!
      @running = false
      @fully_booted = false
      @conn.close
      logger.debug "#{self.class}.logoff!: Disconnected!"
    end

    def send_action(action : AMIData)
      action["actionid"] ||= UUID.random.to_s
      logger.debug "#{self.class}.send_action: ... sending #{action}"
      @event_channel = Channel::Unbuffered(AMIData).new
      @tracked_event.send action["actionid"]
      send!(action)
      logger.debug "#{self.class}.send_action: >>> sent, waiting for response"
      response = @event_channel.not_nil!.receive
      logger.debug "#{self.class}.send_action: <<< response received: #{response}"
      response
    end

    private def listen
      disconnect_and_raise LoginError.new("Already running!") if running?
      running!
      spawn do
        logger.debug "#{self.class}.listen: Starting connection listener"
        respond_to = future { @tracked_event.receive }
        while running?
          data = read!
          logger.debug "#{self.class}.listen: <<< AMI data received: #{data}"
          data = format(data.gsub("\r\n\r\n", "").split("\r\n"))
          logger.debug "#{self.class}.listen: Formatted data: #{data}"

          if respond_to.completed?
            logger.debug "#{self.class}.listen: respond_to.completed?: #{respond_to.completed?.to_s}"
            actionid = respond_to.get
            logger.debug %(#{self.class}.listen: action_id: #{actionid}, data["actionid"]: #{data["actionid"]?})
            if data["actionid"]? == actionid
              # modify tracked data to the pair id => listener
              logger.debug "#{self.class}.listen: <<< sending response"
              @event_channel.not_nil!.send data
            end
            logger.debug "#{self.class}.listen: Restarting connection listener"
            respond_to = future { @tracked_event.receive }
          end

          # do something with data, process hooks etc!

          # FullyBooted event raised by AMI when all Asterisk initialization
          # procedures have finished.
          fully_booted! if data["event"]? == "FullyBooted"

          # Does asterisk get terminated elsewhere?
          if data["event"]? == "Shutdown" || data == {"unknown" => ""}
            logoff!
          end
        end
        logger.debug "#{self.class}.listen: Connection gone, login again!"
      end
    end

    # Format action as a multiline string delimited by "\r\n" and send it
    # through AMI TCPSocket connection
    private def send!(action : AMIData)
      multiline_string = ""
      action.each do |k, v|
        multiline_string += "#{k}: #{v}\r\n"
      end
      # ending string
      multiline_string += "\r\n"
      # send! TODO: rescue errors
        @conn << multiline_string
    rescue ex
      disconnect_and_raise ex
    end

    # Read data from AMI. Usually it's an AMI event, that could be formatted as
    # a json/hash, but it could be also an confirmation to the past action both
    # as a hash or as a string.
    # Data, that AMi returns is a set of a single or multiple strings
    # delimitered by "\r\n" at the end one more terminating ("\r\n")
    private def read! : String
      @conn.gets("\r\n\r\n").to_s
    rescue IO::Timeout
      # Unstable connection, causing no data or broken data
      disconnect_and_raise ConnectionError.new("TCPSocket timeout error")
    rescue ex
      disconnect_and_raise ex
    end

    # `format` process multi-line array by each string, splitting it
    # into key => value pair
    private def format(data : Array) : AMIData
      logger.debug "#{self.class}.format: AMI data received: #{data.empty? ? "(empty string)" : data}"

      # AMI send back empty string as a response to action "logoff"
      # return "" if data.size == 1 && data.first.empty?

      result = AMIData.new

      data.each do |line|
        # Normally Asterisk manager event or confirmation for action containing
        # key-value pair delimited by ": ", except string confirmations or data
        # for user-event without delimiter, these will be assigned as unknown key
        # Examples:
        #
        # "event: SuccessfulAuth" => ["event", "SuccessfulAuth"]
        #
        # "CoreShowChannels: List currently active channels.  (Priv: system,reporting,all)" =>
        # ["CoreShowChannels", "List currently active channels.  (Priv: system,reporting,all)"]
        logger.debug "#{self.class}.format: processing line: #{line}"
        if line =~ /(\S+): (.+)/
          result[$1.to_s.downcase] = $2.to_s.strip
        else
          result["unknown"] = result["unknown"]?.to_s + line
        end
      end

      result
    end
  end
end
