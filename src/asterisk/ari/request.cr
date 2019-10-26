module Asterisk
  class ARI
    class Request
      @uri : String
      @params = Hash(String, String).new

      def uri
        # uri + params
      end

      def initialize(@uri)
      end

      def add(**params)
        params.each do |key, value|
          @params[key] = value.to_s if value
        end
      end
    end
  end
end
