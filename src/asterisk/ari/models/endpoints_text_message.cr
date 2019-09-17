#------------------------------------------------------------------------------
#
#  WARNING !
#
#  This is a generated file. DO NOT EDIT THIS FILE! Your changes will
#  be lost the next time this file is regenerated.
#
#  This file was generated using ctiapps/asterisk crystal shard from the
#  Asterisk PBX version 16.5.1.
#
#------------------------------------------------------------------------------

module Asterisk
  class ARI
    class Endpoints < Resources
      # A text message.
      struct TextMessage
        include JSON::Serializable

        # A technology specific URI specifying the source of the message. For sip and pjsip technologies, any SIP URI can be specified. For xmpp, the URI must correspond to the client connection being used to send the message.
        property from : String

        # A technology specific URI specifying the destination of the message. Valid technologies include sip, pjsip, and xmp. The destination of a message should be an endpoint.
        property to : String

        # The text of the message.
        property body : String

        # Technology specific key/value pairs associated with the message.
        property variables : Array(Endpoints::TextMessageVariable)? = nil
      end
    end
  end
end
