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
require "./event.cr"

module Asterisk
  class ARI
    class Events < Resources
      # The state of a contact on an endpoint has changed.
      struct ContactStatusChange < Event
        property endpoint : Int32

        property contact_info : ContactInfo
      end
    end
  end
end
