require "./logger.cr"
require "socket"
require "uuid"
require "./ami/*"

module Asterisk
  class AMI
    alias EventName = String
    alias ActionID = String
    alias AMIData = Hash(String, String | Array(String))

    @conn = TCPSocket.new
    @connected = false
    @running = false
    @fully_booted = false
    @event_callbacks = Hash(EventName, Proc(AMI, Event, Nil)).new
    getter logger : Logger = Asterisk.logger
    getter receiver : Receiver = Receiver.new(logger: logger)
    getter ami_version : String?
    getter asterisk_version : String?
    getter asterisk_platform : String?

    class LoginError < Exception
    end

    class NotBootedError < Exception
    end

    class ConnectionError < Exception
    end

    # close client and raise error
    private def raise(ex : Exception)
      close
      ::raise ex
    end

    # on_close callback
    def on_close(&@on_close : AMI ->)
    end

    # on_event callback (event name, AMI instance, event body)
    def on_event(event : EventName, &block : AMI, Event ->)
      @event_callbacks[event.to_s.downcase] = block
    end

    def initialize(@host = "127.0.0.1", @port = "5038", @username = "", @secret = "", @logger : Logger = Asterisk.logger)
    end

    def connected?
      @connected && running? && fully_booted?
    end

    def login
      raise LoginError.new("Already connected, logoff first") if @connected
      @conn = TCPSocket.new(@host, @port)
      @conn.sync = true
      @conn.keepalive = false
      run
      response = send_action({"action" => "Login", "username" => @username, "secret" => @secret})
      if response.success?
        # {"unknown" => "Asterisk Call Manager/2.10.5",
        #  "response" => "Success",
        #  "message" => "Authentication accepted"}
        @ami_version = response["unknown"].as(String).split("/").last
        @connected = true
        # AMI should enqueue FullyBooted event that will be processed by runner
        sleep 0.03
        unless fully_booted?
          raise NotBootedError.new("After logn, AMI shoud respond with FullyBooted event")
        end
        # last thing, get asterisk version
        version_information = command("core show version")
        version_information =~ /Asterisk (\d{1,2}.\d{1,2}.\d{1,2}).+on a (\S+)/
        @asterisk_version = $1
        @asterisk_platform = $2
        logger.debug "#{self.class}.login: Logged in"
      else
        raise LoginError.new(response.message)
      end
    end

    def logoff
      if running?
        response = send_action({"action" => "Logoff"})
        # {"response" => "Goodbye", "message" => "Thanks for all the fish."}
        if response.response == "Goodbye"
          logger.debug "#{self.class}.logoff: Logged off"
        else
          logger.error "#{self.class}.logoff: Logged off with incorrect response: #{response}"
        end
      end
      close
    end

    def command(command : String) : String | Array(String)
      result = send_action({"action" => "Command", "command" => command}).output
      if result.size == 1
        result.first
      else
        result
      end
    end

    # increase expects_answer_before with heavy loaded CPU
    def send_action(action : AMIData, expects_answer_before : Float64 = 0.3)
      actionid = action["actionid"] ||= UUID.random.to_s
      @receiver = Receiver.new(logger: logger)
      response = receiver.get(actionid: actionid, expects_answer_before: expects_answer_before) do
        conn_send(action)
      end
      logger.debug "#{self.class}.send_action: response received: #{response.inspect}"
      response
    end

    # Format action as a multiline string delimited by "\r\n" and send it
    # through AMI TCPSocket connection
    private def conn_send(action : AMIData)
      # Asterisk AMI action is a multi-line string delimited by "\r\n" following
      # with one empty strring
      action_s = ""
      action.each do |k, v|
        action_s += "#{k}: #{v}\r\n"
      end
      action_s += "\r\n"
      @conn << action_s
    rescue ex
      raise ex
    end

    private def run
      @running = true
      spawn do
        logger.debug "#{self.class}.run: Starting"
        while running?
          io_data = conn_read
          data = format(io_data)
          logger.debug "#{self.class}.run: Formatted data: #{data.inspect}"

          # Are asterisk get terminated elsewhere?
          # (empty strings are coming to the AMI interface in some cases of
          # forced process termination; in such case Asterisk does not send
          # "Shutdown" event
          close if data.to_h == {"unknown" => ""}

          if receiver.waiting?
            # received message is an AMI unstructured (text) information
            # message that comes as response right after actin was send OR
            # that's response of action containing same actionid as receiver
            if !data.is_a?(Event) && data.actionid?.nil? && !data.response_present?
              receiver.send data
              # logger.debug "#{self.class}.run: <<< sending response: #{data.inspect} to receiver: #{receiver.inspect}"
            elsif data.actionid_present? && data.actionid == receiver.actionid
              receiver.send data
              # logger.debug "#{self.class}.run: <<< sending response: #{data.inspect} to receiver: #{receiver.inspect}"
            end
          end

          if data.is_a?(Event)
            # FullyBooted event raised by AMI when all Asterisk initialization
            # procedures have finished.
            @fully_booted = true if data.event == "FullyBooted"

            # Does asterisk get terminated elsewhere?
            close if data.event == "Shutdown"

            # do something with data, process hooks etc!
            trigger_callback data
          end
        end
      end
    end

    # Read AMI data, which is event, or response/confirmation to the enqueued
    # action. AMI always return data as a set of multiple strings
    # delimitered by "\r\n" with one empty string at the end ("\r\n\r\n")
    private def conn_read : String
      data = @conn.gets("\r\n\r\n").to_s
      # logger.debug "#{self.class}.conn_read: <<< AMI data received: #{data}"
      data
    rescue IO::Timeout
      raise ConnectionError.new("TCPSocket timeout error")
    rescue ex
      # Connection error triggered after @conn.close could be ignored
      if running?
        raise ex
      else
        ""
      end
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
          result["output"] = line.gsub(/--END COMMAND--$/, "").chomp.split("\n")
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

    private def trigger_callback(event : Event)
      name = event.event.to_s.downcase
      @event_callbacks[name]?.try &.call(self, event)
    end

    private def close
      return unless running?
      @connected = false
      @running = false
      @fully_booted = false
      @conn.close
      @on_close.try &.call(self)
    end

    private def running?
      @running
    end

    private def fully_booted?
      @fully_booted
    end
  end
end
