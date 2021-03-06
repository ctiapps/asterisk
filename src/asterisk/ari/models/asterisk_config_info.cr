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
    class Asterisk < Resources
      # Info about Asterisk configuration
      struct ConfigInfo
        include JSON::Serializable

        # Asterisk system name.
        property name : String

        # Default language for media playback.
        property default_language : String

        # Maximum number of simultaneous channels.
        property max_channels : Int32? = nil

        # Maximum number of open file handles (files, sockets).
        property max_open_files : Int32? = nil

        # Maximum load avg on system.
        property max_load : Float32? = nil

        # Effective user/group id for running Asterisk.
        property setid : Asterisk::SetId
      end
    end
  end
end
