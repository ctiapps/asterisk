require "../logger.cr"
require "./*"

module Asterisk
  class AGI
    # AGI response
    struct Response
      property response : String
      property return_code : String
      property result : String
      property additional_data : String

      def initialize(@response = "", @return_code = "", @result = "", @additional_data = "")
      end
    end

    # TODO (fix it based on asterisk_env data.
    # Prior version 1.6 (don't remember) it were "|"
    getter parameters_delimiter = ","
    # response of last recent command
    getter response = Response.new

    getter asterisk_env = Hash(String, String).new
    getter logger : Logger = Asterisk.logger
  end
end
