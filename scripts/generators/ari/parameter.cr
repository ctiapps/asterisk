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
          datatype.gsub("-- none --",      "-- none --").
                   gsub(/(?<!\w)(?<!\b::)AsteriskInfo(?!\w+)/,        "Asterisk::AsteriskInfo").
                   gsub(/(?<!\w)(?<!\b::)AsteriskPing(?!\w+)/,        "Asterisk::AsteriskPing").
                   gsub(/(?<!\w)(?<!\b::)BuildInfo(?!\w+)/,           "Asterisk::BuildInfo").
                   gsub(/(?<!\w)(?<!\b::)ConfigInfo(?!\w+)/,          "Asterisk::ConfigInfo").
                   gsub(/(?<!\w)(?<!\b::)ConfigTuple(?!\w+)/,         "Asterisk::ConfigTuple").
                   gsub(/(?<!\w)(?<!\b::)LogChannel(?!\w+)/,          "Asterisk::LogChannel").
                   gsub(/(?<!\w)(?<!\b::)Module(?!\w+)/,              "Asterisk::Module").
                   gsub(/(?<!\w)(?<!\b::)SetId(?!\w+)/,               "Asterisk::SetId").
                   gsub(/(?<!\w)(?<!\b::)SystemInfo(?!\w+)/,          "Asterisk::SystemInfo").
                   gsub(/(?<!\w)(?<!\b::)Variable(?!\w+)/,            "Asterisk::Variable").
                   gsub(/(?<!\w)(?<!\b::)Application(?!\w+)/,         "Applications::Application").
                   gsub(/(?<!\w)(?<!\b::)Bridge(?!\w+)/,              "Bridges::Bridge").
                   gsub(/(?<!\w)(?<!\b::)Channel(?!\w+)/,             "Channels::Channel").
                   gsub(/(?<!\w)(?<!\b::)CallerID(?!\w+)/,            "Channels::CallerID").
                   gsub(/(?<!\w)(?<!\b::)Dialed(?!\w+)/,              "Channels::Dialed").
                   gsub(/(?<!\w)(?<!\b::)DialplanCEP(?!\w+)/,         "Channels::DialplanCEP").
                   gsub(/(?<!\w)(?<!\b::)RTPStat(?!\w+)/,             "Channels::RTPStat").
                   gsub(/(?<!\w)(?<!\b::)DeviceState(?!\w+)/,         "DeviceStates::DeviceState").
                   gsub(/(?<!\w)(?<!\b::)Endpoint(?!\w+)/,            "Endpoints::Endpoint").
                   gsub(/(?<!\w)(?<!\b::)TextMessageVariable(?!\w+)/, "Endpoints::TextMessageVariable").
                   gsub(/(?<!\w)(?<!\b::)TextMessage(?!\w+)/,         "Endpoints::TextMessage").
                   gsub(/(?<!\w)(?<!\b::)Mailbox(?!\w+)/,             "Mailboxes::Mailbox").
                   gsub(/(?<!\w)(?<!\b::)Playback(?!\w+)/,            "Playbacks::Playback").
                   gsub(/(?<!\w)(?<!\b::)LiveRecording(?!\w+)/,       "Recordings::LiveRecording").
                   gsub(/(?<!\w)(?<!\b::)StoredRecording(?!\w+)/,     "Recordings::StoredRecording").
                   gsub(/(?<!\w)(?<!\b::)FormatLangPair(?!\w+)/,      "Sounds::FormatLangPair").
                   gsub(/(?<!\w)(?<!\b::)Sound(?!\w+)/,               "Sounds::Sound")
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
