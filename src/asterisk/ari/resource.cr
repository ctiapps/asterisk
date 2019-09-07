module Asterisk
  class ARI
    abstract class Resource
      getter client : ARI

      def initialize(@client)
      end
    end
  end
end
