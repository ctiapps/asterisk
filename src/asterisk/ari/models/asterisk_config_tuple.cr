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
      # A key/value pair that makes up part of a configuration object.
      struct ConfigTuple
        include JSON::Serializable

        # A configuration object attribute.
        property attribute : String

        # The value for the attribute.
        property value : String
      end
    end
  end
end
