require "./logger.cr"
require "socket"
require "uuid"

module Asterisk
  class AMI
    @logger : Logger = Asterisk.logger
    getter logger

    @conn = TCPSocket.new
    @running = false
    @fully_booted = false

    alias AMIData = Hash(String, String | Nil)

    class LoginError < Exception
    end

    class NotBootedError < Exception
    end

    class ConnectionError < Exception
    end

    private def raise(ex : Exception)
      # close everything and raise error
      logoff!
    ensure
      ::raise ex
    end

    # Receiver basically create new pair actionid => channel and that let AMI
    # listener method to respond to the send_action after it have enquire action
    # channel is an single-use item, so all data will be vanished immediately
    # after it get received
    class Receiver
      @input = Channel::Unbuffered(AMIData).new
      @@processors = Hash(String, Receiver).new

      @logger : Logger = Asterisk.logger
      getter logger

      def initialize(@id : String)
        @@processors[id] = self
      end

      def get : AMIData
        message = @input.receive
        logger.debug "#{self.class}.get: received #{message}"
        terminate!
        message
      end

      def send(message : AMIData)
        @input.send message
      end

      def terminate!
        @input.close
        @@processors.delete(@id)
      end

      def self.find(id : String)
        @@processors[id]?
      end

      def self.terminate(id : String)
        find(id).try &.terminate!
      end

      def self.terminate!
        # {id, processor}.last => processor
        @@processors.each &.last.terminate
      end
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
          raise NotBootedError.new("Asterisk did not respond with FullyBooted event")
        end
      else
        raise LoginError.new(response["message"])
      end
    end

    def logoff
      logger.debug "#{self.class}.logoff: Preparing"
      if running?
        logger.debug "#{self.class}.logoff: Logging off"
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
      actionid = action["actionid"] ||= UUID.random.to_s
      logger.debug "#{self.class}.send_action: sending #{action}"
      receiver = Receiver.new(id: actionid)
      send!(action)
      logger.debug "#{self.class}.send_action: sent, waiting for response"
      response = receiver.get
      logger.debug "#{self.class}.send_action: response received: #{response}"
      response
    end

    private def listen
      raise LoginError.new("Already running!") if running?
      running!
      spawn do
        logger.debug "#{self.class}.listen: Starting connection listener"
        while running?
          data = read!
          logger.debug "#{self.class}.listen: <<< AMI data received: #{data}"
          data = format(data.gsub("\r\n\r\n", "").split("\r\n"))
          logger.debug "#{self.class}.listen: Formatted data: #{data}"

          if data.has_key?("actionid")
            receiver = Receiver.find(data["actionid"].not_nil!)
            if receiver
              logger.debug %(#{self.class}.listen: receiver: #{receiver.inspect})
              logger.debug "#{self.class}.listen: <<< sending response"
              receiver.not_nil!.send data
            end
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
      raise ex
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
      raise ConnectionError.new("TCPSocket timeout error")
    rescue ex
      raise ex
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

    def connected?
      running? && fully_booted?
    end

    private def running?
      @running
    end

    private def running!
      @running = true
    end

    private def fully_booted!
      @fully_booted = true
    end

    private def fully_booted?
      @fully_booted
    end
  end
end
