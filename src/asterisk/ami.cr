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

    alias AMIData = Hash(String, String)
    @tracked_event = Channel::Unbuffered(String).new
    @event_channel : Channel::Unbuffered(AMIData)?

    class LoginError < Exception
    end

    class ConnectionError < Exception
    end

    class Action
      property action   : String
      property actionid : String = rand.to_s

      @unmapped = AMIData.new

      def instance_vars
        {{ @type.instance_vars.map &.name.stringify }}
      end

      def initialize(**data)
        @action   = data[:action]
        # actionid is mandatory in order to track action response
        @actionid = data[:actionid]? || UUID.random.to_s

        data.each do |k,v|
          k = k.to_s
          @unmapped[k] = v unless instance_vars.includes?(k)
        end
      end

      def to_h
        h = AMIData.new
        {% for ivar in @type.instance_vars %}
          {% key = ivar.name.stringify %}
          {% unless key == "unmapped" %}
            h[{{key}}] = {{ivar}}
          {% end %}
        {% end %}
        h.merge!(@unmapped)
        h
      end
    end

    def initialize(@host = "127.0.0.1", @port = "5038", @username = "", @secret = "", @logger : Logger = Asterisk.logger)
    end

    def login
      @conn = TCPSocket.new(@host, @port)
      @conn.keepalive = true
      action = Action.new action: "Login", username: @username, secret: @secret
      send! action.to_h
      response = read_from_ami
      # wait_fully_booted
      logger.debug "login action and response: #{response}"
      if response["response"] == "Success"
        # running but FullyBooted event shall be also processed
        run_listener
      else
        raise LoginError.new(response["message"])
      end
    end

    def running?
      @running
    end

    private def set_running!
      @running = true
      @last_action = ""
      @last_event = ""
      logger.debug "Running!"
    end

    def logoff
      if running?
        unless @last_action =~ /Logoff/i || @last_event =~ /Shutdown/i
          logger.debug "Will logoff"
          send_action({"action" => "Logoff"})
        end
      end
    ensure
      @running = false
      @last_action = ""
      @last_event = ""
      logger.debug "Logged off"
      @conn.close
    end

    def send_action(action : AMIData)
      @last_action = action["action"]
      logger.info "send_action: sending #{action}"
      @event_channel = Channel::Unbuffered(AMIData).new
      @tracked_event.send action["actionid"]
      send!(action)
      logger.info "send_action: sent, waiting for response"
      response = @event_channel.not_nil!.receive
      logger.info "send_action, response received: #{response}"
      response
    end

    private def run_listener
      set_running!
      spawn do
        logger.info "Starting connection listener"
        respond_to = future { @tracked_event.receive }
        while running?
          event = read_from_ami
          if respond_to.completed?
            logger.info "respond_to.completed?: #{respond_to.completed?.to_s}"
            actionid = respond_to.get
            logger.info %(action_id: #{actionid}, event["actionid"]: #{event["actionid"]})
            if event["actionid"] == actionid
              # modify tracked event to the pair id => listener
              @event_channel.not_nil!.send event
            end
            respond_to = future { @tracked_event.receive }
          end
          # do something with event!
        end
        logger.info "Connection gone, login again!"
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
      # send!
      @conn << multiline_string
    end

    # Read data from AMI. Usually it's an AMI event, that could be formatted as
    # a json/hash, but it could be also an confirmation to the past action both
    # as a hash or as a string.
    # Data, that AMi returns is a set of a single or multiple strings
    # delimitered by "\r\n" at the end one more terminating ("\r\n")
    private def read_from_ami : AMIData
      # in case of TCPSocket failure, return "" that considered as logoff
      data = @conn.gets("\r\n\r\n").to_s rescue ""
      logger.debug "AMI data received: #{data}"
      data = parse_ami_data data.gsub("\r\n\r\n", "").split("\r\n")
      logger.info "Processed dataset: #{data}"

      # if data.empty? && (@last_action =~ /Logoff/i || @last_event =~ /Shutdown/i)
      #   logoff
      #   @last_event = ""
      # else
      #   @last_event = data["event"] rescue "NOOP"
      # end

      data
    rescue IO::Timeout
      # Unstable connection, causing no data or broken data
      raise ConnectionError.new("TCPSocket timeout error")
    end

    private def readline : String
      line = @conn.gets("\r\n")
      logger.debug "AMI line received: #{line}"
      line
    rescue IO::Timeout
      # Unstable connection, causing no data or broken data
      raise ConnectionError.new("TCPSocket timeout error")
    end

    # `parse_ami_data` process multi-line array by each string, splitting it
    # into key => value pair
    private def parse_ami_data(data : Array) : AMIData
      logger.debug "AMI data received: #{data.empty? ? "(empty string)" : data}"

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
        logger.debug "parse_ami_data: processing line: #{line}"
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
