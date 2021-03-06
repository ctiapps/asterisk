# ------------------------------------------------------------------------------
#
#  WARNING !
#
#  This is a generated file. DO NOT EDIT THIS FILE! Your changes will
#  be lost the next time this file is regenerated.
#
#  This file was generated using ctiapps/asterisk crystal shard from the
#  Asterisk PBX version 16.6.0.
#
# ------------------------------------------------------------------------------

module Asterisk
  class ARI
    class Channels < Resources
      # ExternalMedia session.
      struct ExternalMedia
        include JSON::Serializable

        # The Asterisk channel representing the external media
        property channel : Channels::Channel

        # The local ip address used
        property local_address : String? = nil

        # The local ip port used
        property local_port : Int32? = nil
      end
    end
  end
end
