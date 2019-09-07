require "./logger.cr"
require "./agi/core.cr"

module Asterisk
  class AGI
    # Asterisk communicate AGI through STDIN/STDOUT
    # and with FastAGI using TCPSocket
    @input : IO::FileDescriptor | TCPSocket = STDIN
    @output : IO::FileDescriptor | TCPSocket = STDOUT

    def initialize(@input = STDIN, @output = STDOUT, @logger : Logger = Asterisk.logger)
      # right after connection with AGI, asterisk do send key-value set of
      # environment parameters
      read_asterisk_env
    end

    # During AGI initiation, Asterisk do send formatted data: parameters and
    # environment data (param_name: value); method `read_asterisk_env` do read data
    # from the input channel and store them to the @asterisk_env
    private def read_asterisk_env
      loop do
        asterisk_env_data_pair = @input.gets.as(String)
        logger.debug "<<< received asterisk_env property: #{asterisk_env_data_pair}"

        break if asterisk_env_data_pair.empty?

        name, value = asterisk_env_data_pair.as(String).split(": ")
        @asterisk_env[name] = value
      end
      asterisk_env
    end

    # Exec AGI/FastAGI command
    private def execute(command : String)
      logger.debug ">>> executing AGI command: #{command}"
      @output.print "#{command}\n"
      read_response
    end

    private def read_response : Response
      response = ""
      loop do
        response += @input.gets.as(String).chomp
        logger.error "response: #{response}"
        break if response =~ /^\d{3}/
      end
      match = response.match(/^(\d{3}) result=(0[\d*]+|-?[\d*#]+|\(timeout\))(?: (.+)|)/).not_nil!
      @response = Response.new response: match[0], # original asterisk response
        return_code: match[1],                     # 200 is expected
        result: match[2],
        additional_data: match[3]?.to_s
      logger.debug "<<< received AGI response #{response.inspect}"
      @response
    end
  end
end
