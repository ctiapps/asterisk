require "./response"

module Asterisk
  class AMI
    class Event < Response
      def_property event, String
    end
  end
end
