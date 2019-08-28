module Asterisk
  module Generator
    class ARI
      class Parameter
        getter parameter_json    : JSON::Any
        property  name           : String
        property? param_type     : String?
        property? allow_multiple : Bool?
        property? required       : Bool?
        property  description    : String
        property  datatype       : String = ""

        @doc = <<-END
               END

        # are default_value specified?
        def default_value?
          parameter_json["defaultValue"]?
        end

        def default_value
          parameter_json["defaultValue"]?
        end

        private def from_swagger(datatype)
          case datatype
          when /bool/i
            "Bool"
          when /strng/i
            "String"
          when /long/i
            "Int64"
          when /int/i
            "Int32"
          when /double/i
            "Float32"
          when /Date/i
            "Time"
          when /containers|object/i
            "Hash(String, String | Bool | Int32 | Float32)"
          when /^List\[(\w+)\]$/i
            "Array(#{$1.camelcase})"
          else
            datatype.camelcase
          end
        end

        private def classify(datatype)
          datatype.gsub("-- none --",          "-- none --").
                   gsub("Application",         "Applications::Application").
                   gsub("Bridge",              "Bridges::Bridge").
                   gsub("Channel",             "Channels::Channel").
                   gsub("CallerID",            "Channels::CallerID").
                   gsub("Dialed",              "Channels::Dialed").
                   gsub("DialplanCEP",         "Channels::DialplanCEP").
                   gsub("RTPStat",             "Channels::RTPStat").
                   gsub("DeviceState",         "DeviceStates::DeviceState").
                   gsub("Endpoint",            "Endpoints::Endpoint").
                   gsub("TextMessage",         "Endpoints::TextMessage").
                   gsub("Mailbox",             "Mailboxes::Mailbox").
                   gsub("Playback",            "Playbacks::Playback").
                   gsub("LiveRecording",       "Recordings::LiveRecording").
                   gsub("StoredRecording",     "Recordings::StoredRecording").
                   gsub("FormatLangPair",      "Sounds::FormatLangPair").
                   gsub("Sound",               "Sounds::Sound").
                   gsub("Sounds::Sounds",      "Sounds")
        end

        private def set_datatype()
          datatype = (parameter_json["dataType"]? || parameter_json["type"]).as_s
          datatype = from_swagger(datatype)
          # because resulting model names are stored behind related resource,
          # lets replace to match
          result = classify(datatype)

          if ! required?
            result += "?"
          end

          if default_value?
            if datatype == "String"
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
          @parameter_json.as_h.delete("name")
          @required       = parameter_json["required"]?.try &.as_bool
          @param_type     = parameter_json["paramType"]?.try &.as_s
          @allow_multiple = parameter_json["allowMultiple"]?.try &.as_bool
          set_datatype
          @description    = (parameter_json["description"]? || parameter_json["descriptioni"]?).to_s
        end

      end
    end
  end
end
