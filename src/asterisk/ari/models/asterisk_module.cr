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
      # Details of an Asterisk module
      struct Module
        include JSON::Serializable

        # The name of this module
        property name : String

        # The description of this module
        property description : String

        # The number of times this module is being used
        property use_count : Int32

        # The running status of this module
        property status : String

        # The support state of this module
        property support_level : String
      end
    end
  end
end
