#------------------------------------------------------------------------------
#
#  WARNING !
#
#  This is a generated file. DO NOT EDIT THIS FILE! Your changes will
#  be lost the next time this file is regenerated.
#
#  This file was generated using ctiapps/asterisk crystal shard from the
#  Asterisk PBX version 16.6.0.
#
#------------------------------------------------------------------------------
require "./event.cr"

module Asterisk
  class ARI
    class Events < Resources
      # Notification that an attended transfer has occurred.
      struct BridgeAttendedTransfer < Event

        # First leg of the transferer
        property transferer_first_leg : Channels::Channel

        # Second leg of the transferer
        property transferer_second_leg : Channels::Channel

        # The channel that is replacing transferer_first_leg in the swap
        property replace_channel : Channels::Channel? = nil

        # The channel that is being transferred
        property transferee : Channels::Channel? = nil

        # The channel that is being transferred to
        property transfer_target : Channels::Channel? = nil

        # The result of the transfer attempt
        property result : String

        # Whether the transfer was externally initiated or not
        property is_external : Bool

        # Bridge the transferer first leg is in
        property transferer_first_leg_bridge : Bridges::Bridge? = nil

        # Bridge the transferer second leg is in
        property transferer_second_leg_bridge : Bridges::Bridge? = nil

        # How the transfer was accomplished
        property destination_type : String

        # Bridge that survived the merge result
        property destination_bridge : String? = nil

        # Application that has been transferred into
        property destination_application : String? = nil

        # First leg of a link transfer result
        property destination_link_first_leg : Channels::Channel? = nil

        # Second leg of a link transfer result
        property destination_link_second_leg : Channels::Channel? = nil

        # Transferer channel that survived the threeway result
        property destination_threeway_channel : Channels::Channel? = nil

        # Bridge that survived the threeway result
        property destination_threeway_bridge : Bridges::Bridge? = nil
      end
    end
  end
end
