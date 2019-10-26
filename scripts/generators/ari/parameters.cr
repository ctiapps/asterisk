module Asterisk
  module Generator
    class ARI
      class Parameters
        enum ModelType
          Resource
          Model
        end

        getter parameters_json : JSON::Any
        getter model_type : ModelType
        getter parameters = {} of String => Parameter
        # indicate types of parameters to build HTTP request
        getter path_type = [] of Parameter
        getter query_type = [] of Parameter
        getter body_type = [] of Parameter

        # returns a string with method arguments from parameters "def(arguments)"
        def arguments
          result = ""
          parameters.each do |name, parameter|
            if model_type.is_a?(ModelType::Model)
              result += %(@#{name}#{parameter.datatype}, )
            else
              result += %(#{name}#{parameter.datatype}, )
            end
          end
          result.gsub(/, $/, "")
        end

        def arguments_spec
          if parameters_json.as_a?
            spec = "\nArguments:\n"
            parameters_json.as_a.sort_by! do |parameter|
              name = parameter.as_h["name"].as_s.underscore
              parameter = parameters[name]
              description = parameter.description[0].downcase + parameter.description[1..2000] + "."
              description = description.gsub(/\.\.$/, ".")
              spec += %(- `#{name}` - #{description})
              spec += " (required)" if parameter.required?
              spec += ". Allow multiple instances (comma-separated list)" if parameter.allow_multiple?
              spec = spec.gsub(/\.$/, "")
              spec += ";\n"
            end
            "\n" + spec.chomp.gsub(/^/m, "      # ")
          else
            ""
          end
        end

        def struct_properties
          structure = ""
          parameters.each do |name, parameter|
            # pp parameter
            structure += <<-END
                         #{parameter.description.to_s.empty? ? "" : %(\n#{parameter.description.gsub(/^/m, "        # ")})}
                                 property #{name}#{parameter.datatype}

                         END
          end
          structure
        end

        # Preparing parameters to be processed.
        # Parameters are different for resources and models:
        #
        # For resources is's an array behind JSON property "parameters":
        # ```
        # [{"name"          => "body",
        #   "description"   => "The body of the message",
        #   "paramType"     => "query",
        #   "required"      => false,
        #   "allowMultiple" => false,
        #   "dataType"      => "string"}]
        # ```
        #
        # For models it's a hash behind JSON property "properties":
        # ```
        # { "something => { "..." => "..." },
        # { "state" => {
        #   "type" => "string",
        #   "description" => "Endpoint's state",
        #   "required" => false,
        #   "allowableValues" =>
        #     {"valueType" => "LIST", "values" => ["unknown", "offline", "online"]}
        #   }
        # }
        # ```
        # TODO: Process:
        # allowMultiple": true,
        def initialize(@parameters_json : JSON::Any)
          if parameters_json.as_a?
            # array - this is resource
            @model_type = ModelType::Resource
          else
            # hash - this is model
            @model_type = ModelType::Model
          end

          if parameters_json.as_a?
            # sort - required first
            parameters_ary = parameters_json.as_a.sort_by! do |parameter|
              if parameter.as_h["paramType"]?.try &.as_s.== "path"
                0
              elsif parameter.as_h["required"]?.try &.as_bool
                1
              else
                2
              end
            end
            parameters_ary.each do |parameter|
              name = parameter.as_h["name"].as_s.underscore
              parameter = @parameters[name] = Parameter.new(name, parameter)
              case parameter.param_type
              when "path"
                @path_type.push parameter
              when "query"
                @query_type.push parameter
              when "body"
                @body_type.push parameter
              end
            end
          else
            # parameters_ary = [] of JSON::Any
            # parameters_json.as_h.each do |name, data|
            #   name = name.underscore
            #   data.as_h["name"] = JSON::Any.new(name)
            #   parameters_ary.push data
            # end
            # # sort - required first
            # parameters_ary.sort_by do |parameter|
            #   (parameter.as_h["required"]?.try &.as_bool || false) ? 1 : 2
            # end

            parameters_json.as_h.each do |name, parameter|
              name = name.underscore
              @parameters[name] = Parameter.new(name, parameter)
            end
          end

          # pp @parameters
        end
      end
    end
  end
end
