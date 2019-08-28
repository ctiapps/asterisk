require "./resource.cr"
require "./events/message.cr"
require "./events/event.cr"
require "./events/*"

module Asterisk
  class ARI
    class Events < Resource
      # list all the included classes
      def self.events
        {% begin %}
          {% events = {} of String => Class %}
          {% @type.constants.map do |klass|
            klass_name = klass.stringify
            unless %w(Message Event).includes?(klass_name)
              events[klass_name] = klass.stringify.id
            end
          end %}
          {{events}}
        {% end %}
      end
    end
  end
end
