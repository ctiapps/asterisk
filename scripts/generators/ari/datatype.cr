module Asterisk
  module Generator
    class ARI
      class Datatype
        getter datatype : String

        def initialize(@datatype)
        end

        def set!
          from_swagger
          classify
          datatype
        end

        private def from_swagger
          @datatype = case datatype
          when /void/
            "Nil"
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

        private def classify
          @datatype = datatype.
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
      end
    end
  end
end
