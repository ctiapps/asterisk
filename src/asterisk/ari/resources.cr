module Asterisk
  class ARI
    abstract class Resources
      getter client : ARI

      def initialize(@client)
      end
    end
  end
end

require "./resources/*"
