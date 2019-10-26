require "./agi/core.cr"
require "uri"

module Asterisk
  class AsyncAGI < AGI
    getter logger : Logger = Asterisk.logger
    getter channel : String = ""
    private getter ami : AMI

    def initialize(@ami, @logger : Logger = Asterisk.logger)
    end

    # environment data (param_name: value); method `read_asterisk_env` do read data
    # from the input channel and store them to the @asterisk_env
    def read_asterisk_env(env_data)
      env_data = URI.decode(env_data)
      env_data.split("\n").each do |asterisk_env_data_pair|
        logger.debug "<<< received asterisk_env property: #{asterisk_env_data_pair}"
        break if asterisk_env_data_pair.empty?
        name, value = asterisk_env_data_pair.as(String).split(": ")
        @asterisk_env[name] = value
      end

      # register channel
      @channel = asterisk_env["agi_channel"]

      asterisk_env
    end

    # Exec AGI command via
    private def execute(command : String)
      logger.debug ">>> executing AGI command: #{command}"
      command_id = UUID.random.to_s
      response = ami.send_action({"Action" => "AGI", "Channel" => channel, "Command" => command, "CommandID" => command_id})
      logger.debug "#{self.class} got response: #{response.inspect}"
      response
    end
  end

  class AsyncAGI::Server
    getter logger : Logger = Asterisk.logger
    private getter ami : AMI

    def initialize(@ami_host = "127.0.0.1", @ami_port : String | Int32 = 5038, @ami_username = "", @ami_secret = "", @logger : Logger = Asterisk.logger)
      @ami = AMI.new host: @ami_host, port: @ami_port, username: @ami_username, secret: @ami_secret, logger: @logger
    end

    def start(&@block : AGI ->)
      # ami.on_event("FullyBooted") do |ami, event|
      # end

      ami.on_event("AsyncAGIStart") do |_, event|
        logger.debug "#{self.class} AMI event #{event.event}: #{event.inspect}"
        # activate new call instance
        call = AsyncAGI.new(ami: @ami, logger: @logger)
        # env setup
        call.read_asterisk_env(event["env"].as(String))
        # register call (call.channel => call)
        # spawn worker
        process(call)
      end

      ami.on_event("AsyncAGIEnd") do |_, event|
        logger.debug "#{self.class} AMI event #{event.event}: #{event.inspect}"
        # stop worker
        # log termination data
        # do post-call stuff
        # unregister call
      end

      # ami.on_close do |ami|
      #   # remove all calls etc
      # end

      ami.start
      # sleep
    end

    def process(call : AsyncAGI)
      spawn do
        @block.try &.call(call)
      end
    end
  end
end
