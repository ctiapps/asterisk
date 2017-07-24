require "./agi/*"

module Asterisk
  class AGI
    @input  : IO::FileDescriptor | TCPSocket
    @output : IO::FileDescriptor | TCPSocket

    class LoginError < Exception
    end

    class ConnectionLostError < Exception
    end

    def initialize(input = STDIN, output = STDOUT)
      @input  = input
      @output = output
      @params = Hash(String, String).new

      get_params
    end

    def logger
      Asterisk.logger
    end

    def get_params
      loop do
        pair = @input.gets
        logger.debug "params line: #{pair}."

        #  agi_request: /var/lib/asterisk/agi-bin/basic
        break if pair == ""

        param_name, param_value = pair.as(String).split(": ")
        @params[param_name] = param_value
      end
    end

    def command(cmd)
      logger.debug "Executing command: #{cmd}."
      @output.puts cmd

      # get response (could be multiline)
      # normally it's format:
      # 200 result=1
      res = ""
      loop do
        r = @input.gets
        res += r.as(String)
        break if r =~ /^\d+ /
      end

      logger.debug "res: #{res}."

      res
    end
  end
end
