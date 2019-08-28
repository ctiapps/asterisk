#------------------------------------------------------------------------------
#
#  WARNING !
#
#  This is a generated file. DO NOT EDIT THIS FILE! Your changes will
#  be lost the next time this file is regenerated.
#
#  This file was generated using ctiapps/asterisk crystal shard from the
#  Asterisk PBX version 16.5.0.
#
#------------------------------------------------------------------------------

module Asterisk
  class ARI
    class Asterisk < Resource
      # Info about how Asterisk was built
      struct BuildInfo
        include JSON::Serializable

        # OS Asterisk was built on.
        property os : String

        # Kernel version Asterisk was built on.
        property kernel : String

        # Compile time options, or empty string if default.
        property options : String

        # Machine architecture (x86_64, i686, ppc, etc.)
        property machine : String

        # Date and time when Asterisk was built.
        property date : String

        # Username that build Asterisk
        property user : String
      end
    end
  end
end
