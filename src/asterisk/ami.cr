require "./logger.cr"
require "socket"
require "uuid"
require "./ami/*"

module Asterisk
  class AMI
    getter logger : Logger = Asterisk.logger

    @conn         = TCPSocket.new
    @running      = false
    @fully_booted = false

    getter receiver : Receiver = Receiver.new

    alias ActionID = String
    alias AMIData = Hash(String, String | Array(String))

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

    def initialize(@host = "127.0.0.1", @port = "5038", @username = "", @secret = "", @logger : Logger = Asterisk.logger)
    end

    def login
      @conn = TCPSocket.new(@host, @port)
      @conn.sync = true
      @conn.keepalive = false
      listen
      response = send_action({"action" => "Login", "username" => @username, "secret" => @secret})
      logger.debug "#{self.class}.login response: #{response}"
      if response.success?
        # running but FullyBooted event shall be also processed
        sleep 0.03
        unless fully_booted?
          raise NotBootedError.new("Asterisk did not respond with FullyBooted event")
        end
      else
        raise LoginError.new(response.message)
      end
    end

    def logoff
      logger.debug "#{self.class}.logoff: Preparing"
      if running?
        logger.debug "#{self.class}.logoff: Logging off"
        response = send_action({"action" => "Logoff"})
        # {"response" => "Goodbye", "message" => "Thanks for all the fish."}
        if response.response == "Goodbye"
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

    def send_action(action : AMIData, expects_answer_before : Float64 = 0.0)
      actionid = action["actionid"] ||= UUID.random.to_s
      @receiver = Receiver.new(actionid: actionid, expects_answer_before: expects_answer_before, logger: logger)
      response = receiver.get do
        send!(action)
        logger.debug "#{self.class}.send_action: sending #{action}"
        logger.debug "#{self.class}.send_action: sent, waiting for response"
      end
      logger.debug "#{self.class}.send_action: response received: #{response.inspect}"
      response
    end

    private def listen
      raise LoginError.new("Already running!") if running?
      running!
      spawn do
        logger.debug "#{self.class}.listen: Starting connection listener"
        while running?
          io_data = read!
          # logger.debug "#{self.class}.listen: <<< AMI data received: #{data}"
          data = format(io_data)
          logger.debug "#{self.class}.listen: Formatted data: #{data.inspect}"

          if receiver.waiting?
            # received message is an AMI unstructured (text) information
            # message that comes as response right after actin was send OR
            # that's response of action containing same actionid as receiver
            if ! data.is_a?(Event) && data.actionid?.nil? && ! data.response_present?
              receiver.send data
              logger.debug "#{self.class}.listen: <<< sending response: #{data.inspect} to receiver: #{receiver.inspect}"
            elsif data.actionid_present? && data.actionid == receiver.actionid
              receiver.send data
              logger.debug "#{self.class}.listen: <<< sending response: #{data.inspect} to receiver: #{receiver.inspect}"
            end
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
      raise ConnectionError.new("TCPSocket timeout error")
    rescue ex
      raise ex
    end

    # `format` process each line of given multi-line string (array), splitting
    # it into key => value pair
    private def format(data : String) : Response
      # convert input data (multi-line string to the array of strings)
      data = data.gsub(/\r\n\r\n$/, "").split("\r\n")

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

        # Logic for
        # ```{"action" => "Command", "command" => "..."}```
        if cli_command && previous_key == "actionid"
          result["output"] = line.gsub(/--END COMMAND--$/, "").split("\n")
          break
        end

        if line =~ /(^[\w\s\/-]*):[\s]*(.*)$/m
          previous_key = key = $1.to_s.downcase
          value = $2.to_s

          # if key already present, then value is an array
          if result.has_key?(key)
            if result[key].is_a?(Array)
              result[key].as(Array).push value
            else
              result[key] = [result[key].as(String)].push value
            end
          else
            result[key] = value
          end

          # Asterisk 13, with multi-line output
          if key == "response" && value == "Follows"
            cli_command = true
          end

          # there were no delimiter, will assign data to the "unknown" key
        else
          key = "unknown"
          if result.has_key?(key)
            if result[key].is_a?(Array)
              result[key].as(Array).push line
            else
              result[key] = [result[key].as(String)].push line
            end
          else
            result[key] = line
          end
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
