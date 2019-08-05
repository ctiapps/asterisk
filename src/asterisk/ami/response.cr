module Asterisk
  class AMI
    class Response
      getter data = AMIData.new
      delegate :[]=, to: @data
      delegate :[]?, to: @data
      delegate :[], to: @data

      macro def_property(property, klass = String)
        def {{property}}=({{property}} : {{klass}})
          data["{{property}}"] = {{property}}
        end

        def {{property}}? : {{klass}}?
          data["{{property}}"]?.as({{klass}} | Nil)
        end

        def {{property}} : {{klass}}
          {{property}}?.not_nil!
        end

        def {{property}}_present? : Bool
          data.has_key?("{{property}}")
        end
      end

      def_property actionid, ActionID
      def_property response, String
      def_property message, String
      def_property value, String
      def_property output, Array(String)

      def success?
        response?.to_s.match /Success/i
      end

      def initialize(data : AMIData? = nil)
        @data.merge! data if data
      end

      def to_h
        @data
      end
    end
  end
end
