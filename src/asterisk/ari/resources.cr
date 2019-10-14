module Asterisk
  class ARI
    abstract class Resources
      getter ari : ARI

      def initialize(@ari)
      end

      private def format_response
        # 200 or 201
        if (response.ok? || response.created?) && ! response.body.nil?
          response.from_json(response.body.to_s)
        else
          response
        end
      end
    end
  end
end

require "./resources/*"
