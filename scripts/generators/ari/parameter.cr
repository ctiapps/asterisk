require "./datatype.cr"

module Asterisk
  module Generator
    class ARI
      class Parameter
        getter parameter_json : JSON::Any
        property name : String
        property name_ari : String
        property param_type : String?
        property? allow_multiple : Bool?
        property? required : Bool?
        property description : String
        property datatype : String = ""

        @doc = <<-END
               END

        # are default_value specified?
        def default_value?
          parameter_json["defaultValue"]?
        end

        def default_value
          parameter_json["defaultValue"]?
        end

        private def set_datatype
          datatype = (parameter_json["dataType"]? || parameter_json["type"]).as_s
          result = Datatype.new(datatype).set!

          if !required?
            result += "?"
          end

          if default_value?
            if datatype == "string"
              result += %( = "#{default_value}")
            else
              result += " = #{default_value}"
            end
          else
            result += " = nil" unless required?
          end

          @datatype = %( : #{result})
        end

        def initialize(@name, @parameter_json)
          @name_ari = parameter_json["name"]?.try &.as_s || ""
          @param_type = parameter_json["paramType"]?.try &.as_s
          @required = param_type == "path" || (parameter_json["required"]?.try &.as_bool)
          # allow_multiple is true for comma-separated data, i.e. soundfiles for
          # play command
          @allow_multiple = parameter_json["allowMultiple"]?.try &.as_bool
          set_datatype
          @description = (parameter_json["description"]? || parameter_json["descriptioni"]?).to_s
        end
      end
    end
  end
end
