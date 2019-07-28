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

    alias ActionID = String
    alias AMIData = Hash(String, String?)

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

    class Response
      @data = AMIData.new
      delegate :[]=, to: @data
      delegate :[], to: @data
      getter data

      def actionid=(actionid : ActionID)
        @data["actionid"] = actionid
      end

      def actionid : ActionID
        @data["actionid"].not_nil!
      end

      def actionid? : ActionID?
        @data["actionid"]?
      end

      def initialize(data : AMIData? = nil)
        @data.merge! data if data
      end

      def to_h
        @data
      end
    end

    class Event < Response
      def event=(event : String)
        @data["event"] = event
      end

      def event : String
        @data["event"].not_nil!
      end
    end

    # Receiver basically id a pair actionid => channel and that let AMI
    # listener method to respond to the send_action after it have enquire action
    # channel is an single-use item, so all data will be vanished immediately
    # after it get received
    class Receiver
      WAIT_FOR_TERMINATE = 0.01
      # expects_answer_before in send_action
      WAIT_FOR_ANSWER = 0.002

      property expects_answer_before : Float64?

      property id : ActionID
      @input = Channel::Unbuffered(Response).new
      @@processors = Hash(String, Receiver).new

      @logger : Logger = Asterisk.logger
      getter logger

      def initialize(@id : ActionID, @expects_answer_before : Float64?)
        @@processors[id] = self
      end

      def get : Response
        stop_after expects_answer_before.not_nil! if expects_answer_before
        data = @input.receive
        logger.debug "#{self.class}.get: received #{data.inspect}"
        terminate!
        data
      rescue Channel::ClosedError
        terminate!
        Response.new({"response" => "Error", "message" => "Timeout error while waiting for AMI response"})
      end

      def stop_after(timeout : Float64)
        spawn do
          started_at  = Time.now
          loop do
            sleep WAIT_FOR_ANSWER
            if (Time.now - started_at).to_f >= timeout
              @input.close
              break
            end
          end
        end
      end

      def send(data : Response)
        @input.send data
      end

      def terminate!
        @input.close
        @@processors.delete(@id)
        sleep WAIT_FOR_TERMINATE
      end

      def self.get(id : ActionID, expects_answer_before : Float64?)
        receiver = Receiver.new(id, expects_answer_before)
        yield
        receiver.get
      end

      def self.find(id : ActionID)
        @@processors[id]?
      end

      def self.current
        actionid = @@processors.keys.last?
        @@processors[actionid] if actionid
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
      if response.to_h["response"] == "Success"
        # running but FullyBooted event shall be also processed
        sleep 0.03
        unless fully_booted?
          raise NotBootedError.new("Asterisk did not respond with FullyBooted event")
        end
      else
        raise LoginError.new(response.to_h["message"])
      end
    end

    def logoff
      logger.debug "#{self.class}.logoff: Preparing"
      if running?
        logger.debug "#{self.class}.logoff: Logging off"
        response = send_action({"action" => "Logoff"})
        # {"response" => "Goodbye", "message" => "Thanks for all the fish."}
        if response.to_h["response"] == "Goodbye"
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

    def send_action(action : AMIData, expects_answer_before : Float64? = 0.3)
      actionid = action["actionid"] ||= UUID.random.to_s
      response = Receiver.get(actionid, expects_answer_before) do
        logger.debug "#{self.class}.send_action: sending #{action}"
        send!(action)
        logger.debug "#{self.class}.send_action: sent, waiting for response"
      end
      logger.debug "#{self.class}.send_action: response received: #{response.inspect}"
      response.to_h
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
          logger.debug "#{self.class}.listen: Formatted data: #{data.inspect}"

          # receiver = if data.is_a?(Event)
          #   Receiver.find(data.actionid) if data.actionid?
          # else
          #   # if data is not event and does not containing "actionid", then we
          #   # try to deliver back to the last registered receiver
          #   Receiver.current
          # end
          receiver = if data.actionid?
            Receiver.find(data.actionid)
          else
            logger.debug "#{self.class}.listen: Not sure who is consumer for data"
            Receiver.current
            # nil
          end

          if receiver
            logger.debug %(#{self.class}.listen: receiver: #{receiver.inspect})
            logger.debug "#{self.class}.listen: <<< sending response"
            receiver.send data
          end

          if data.is_a?(Event)
            # do something with data, process hooks etc!
            # here... TODO...

            # FullyBooted event raised by AMI when all Asterisk initialization
            # procedures have finished.
            fully_booted! if data.event == "FullyBooted"

            # Does asterisk get terminated elsewhere?
            logoff! if data.event == "Shutdown"
          end

          # Does asterisk get terminated elsewhere?
          # (empty strings are coming to the AMI interface in some cases of
          # forced process termination; in such case Asterisk does not send
          # "Shutdown" event
          logoff! if data.to_h == {"unknown" => ""}
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
    private def format(data : Array) : Response
      logger.debug "#{self.class}.format: AMI data received: #{data.empty? ? "(empty string)" : data}"

      result = AMIData.new
      cli_command = false
      previous_key = ""

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

        # logic for
        # {"action" => "Command", "command" => "..."}
        if cli_command && previous_key == "actionid"
          result["result"] = line.split("\n").map(&.chomp.strip).join("\n").gsub(/--END COMMAND--$/, "")
          next
        end

        if line =~ /(^[\w\s\/-]*):[\s]*(.*)$/m
          previous_key = key = $1.to_s.downcase
          # TODO: serializer for value
          value = $2.to_s.strip
          if result.has_key?(key)
            result[key] = "#{result[key]}\n#{value}".strip.chomp
          else
            result[key] = value
          end
          if key = "response" && value == "Follows"
            cli_command = true
          end
        else
          result["unknown"] = result["unknown"]?.to_s + line
        end
      end

      if result.has_key?("event")
        Event.new(result)
      else
        Response.new(result)
      end
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
