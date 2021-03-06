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
      # Event showing the continuation of a media playback operation from one media URI to the next in the list.
      struct PlaybackContinuing < Event
        # Playback control object
        property playback : Playbacks::Playback
      end
    end
  end
end
