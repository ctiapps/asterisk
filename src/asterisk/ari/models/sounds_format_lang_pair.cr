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
    class Sounds < Resources
      # Identifies the format and language of a sound file
      struct FormatLangPair
        include JSON::Serializable

        property language : String

        property format : String
      end
    end
  end
end
