require "./logger.cr"
require "socket"
require "time"
require "uuid"

module Asterisk
  class AMI
    @conn = TCPSocket.new
    @connected = false
    @last_action = ""
    @last_event = ""

    class LoginError < Exception
    end

    class ConnectionError < Exception
    end

    def logger : Logger
      @logger
    end

    def initialize(@host = "127.0.0.1", @port = "5038", @username = "", @secret = "", @logger : Logger = Asterisk.logger)
    end

    def login
      @conn = TCPSocket.new(@host, @port)
      @conn.keepalive = true
      login!
      run_listener
      # wait_fully_booted
    end

    private def login!
      response = send_action({"action" => "Login", "username" => @username, "secret" => @secret})
      if response["response"] == "Success"
        # Connected but FullyBooted event shall be also processed
        connected!
      else
        raise LoginError.new(response["message"])
      end
    end

    def connected?
      @connected
    end

    private def connected!
      @connected = true
      logger.debug "Connected!"
    end

    def logoff
      if connected?
        unless @last_action =~ /Logoff/i || @last_event =~ /Shutdown/i
          logger.debug "Will logoff"
          send_action({"action" => "Logoff"})
        end
      end
    ensure
      @connected = false
      @last_action = ""
      @last_event = ""
      logger.debug "Logged off"
      @conn.close
    end

    def send_action(action)
      # actionid is mandatory in order to track action response
      actionid = action["actionid"] ||= UUID.random.to_s
      send_action!(action)
      response = read_from_ami
      logger.debug "send_action: #{action}\nresponse: #{response}"
      response
    end

    # Format action as a multiline string delimited by "\r\n" and send it
    # through AMI TCPSocket connection
    private def send_action!(action)
      @last_action = action["action"]
      multiline_string = ""
      action.each do |k, v|
        multiline_string += "#{k}: #{v}\r\n"
      end
      # ending string
      multiline_string += "\r\n"

      @conn << multiline_string
    end

    private def run_listener
      spawn do
        logger.info "Starting connection listener"
        while connected?
          # receive_and_process_event
          event = read_from_ami
          logger.info "listener: got data: #{event}"
          # next if event["event"]? == "SuccessfulAuth"

          # unless @confirmation_channel.closed?
          #   @confirmation_channel.send(event)
          #   next
          # end

          if event.empty? && (@last_action =~ /Logoff/i || @last_event =~ /Shutdown/i)
            logoff
            @last_event = ""
          else
            @last_event = event["event"] rescue "NOOP"
          end
        end
        logger.info "Connection gone, login again!"
      end
    end

    # Read data from AMI. Usually it's an AMI event, that could be formatted as
    # a json/hash, but it could be also an confirmation to the past action both
    # as a hash or as a string.
    # Data, that AMi returns is a set of a single or multiple strings
    # delimitered by "\r\n" at the end one more terminating ("\r\n")
    private def read_from_ami
      # in case of TCPSocket failure, return "" that considered as logoff
      data = @conn.gets("\r\n\r\n").to_s rescue ""
      logger.debug "AMI data received: #{data}"
      parse_ami_data data.gsub("\r\n\r\n", "").split("\r\n")
    rescue IO::Timeout
      # Unstable connection, causing no data or broken data
      raise ConnectionError.new("TCPSocket timeout error")
    end

    # `parse_ami_data` process multi-line array by each string, splitting it
    # into key => value pair
    private def parse_ami_data(data : Array)
      logger.debug "AMI data received: #{data.empty? ? "(empty string)" : data}"

      # AMI send back empty string as a response to action "logoff"
      return "" if data.size == 1 && data.first.empty?

      result = {} of String => String

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
        logger.debug "parse_ami_data: processing line: #{line}"
        if line =~ /(\S+): (.+)/
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
