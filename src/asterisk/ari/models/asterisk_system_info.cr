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
    class Asterisk < Resources
      # Info about Asterisk
      struct SystemInfo
        include JSON::Serializable

        # Asterisk version.
        property version : String

        property entity_id : String
      end
    end
  end
end