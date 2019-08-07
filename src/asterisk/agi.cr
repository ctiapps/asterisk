require "./logger.cr"
require "./agi/*"

module Asterisk
  class AGI
    @input  : IO::FileDescriptor | TCPSocket = STDIN
    @output : IO::FileDescriptor | TCPSocket = STDOUT
    @params = Hash(String, String).new

    class LoginError < Exception
    end

    class ConnectionLostError < Exception
    end

    def initialize(@input = STDIN, @output = STDOUT)
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
      @output.print "#{cmd}\n"
      # @output << "\n"

      # get response (could be multiline)
      # normally it's format:
      # 200 result=1
      res = ""
      loop do
        r = @input.gets.as(String).chomp
        res += r
        # break if r =~ /^\d+ /
        break if r =~ /^(\d{3}) result=(0[\d*]+|-?[\d*#]+|\(timeout\))(?: (.+)|)/
      end

      # So asterisk responses have a format. The format is:
      #   <error_code><space>result=<result_data><space>[additional_data]
      # ^(\d{3}) result=(0[\d*]+|-?[\d*#]+|\(timeout\))(?: (.+)|)
      # $1 code #2 result_data $3 additional_data
      logger.debug "res: #{res}."

      res
    end
  end
end
