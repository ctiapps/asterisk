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
      # Notification that the source of video in a bridge has changed.
      struct BridgeVideoSourceChanged < Event
        property bridge : Bridges::Bridge

        property old_video_source_id : String? = nil
      end
    end
  end
end
