require "./logger.cr"
require "./agi/*"

module Asterisk
  class AGI
    # TODO (fix it based on params data.
    # Prior version 1.6 (don't remember) it were "|"
    getter parameters_delimiter = ","
    # response of last recent command
    getter response = Response.new

    @input : IO::FileDescriptor | TCPSocket = STDIN
    @output : IO::FileDescriptor | TCPSocket = STDOUT
    getter params = Hash(String, String).new
    getter logger : Logger = Asterisk.logger

    struct Response
      property response : String
      property return_code : String
      property result : String
      property additional_data : String

      def initialize(@response = "", @return_code = "", @result = "", @additional_data = "")
      end
    end

    def initialize(@input = STDIN, @output = STDOUT, @logger : Logger = Asterisk.logger)
      get_params
    end

    # During AGI initiation, Asterisk do send formatted data: parameters and
    # environment data (param_name: value); method `get_params` do read data
    # from the input channel and store them to the @params
    private def get_params
      loop do
        params_data_pair = @input.gets.as(String)
        logger.debug "<<< received params property: #{params_data_pair}"

        # agi_request: /var/lib/asterisk/agi-bin/basic
        break if params_data_pair.empty?

        name, value = params_data_pair.as(String).split(": ")
        @params[name] = value
      end
      params
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
