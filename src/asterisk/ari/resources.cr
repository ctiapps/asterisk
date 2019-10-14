module Asterisk
  class ARI
    abstract class Resources
      getter ari : ARI

      def initialize(@ari)
      end

      private def format_response(response : HTTP::Client::Response, klass)
        # 200 or 201
        if (response.status.ok? || response.status.created?) && ! response.body.nil?
          klass.from_json(response.body.to_s)
        else
          response
        end
      end
    end
  end
end

require "./resources/*"
