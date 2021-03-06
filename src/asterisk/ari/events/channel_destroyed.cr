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
      # Notification that a channel has been destroyed.
      struct ChannelDestroyed < Event
        # Integer representation of the cause of the hangup
        property cause : Int32

        # Text representation of the cause of the hangup
        property cause_txt : String

        property channel : Channels::Channel
      end
    end
  end
end
