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
require "./event.cr"

module Asterisk
  class ARI
    class Events < Resources
      # A text message was received from an endpoint.
      struct TextMessageReceived < Event

        property message : Endpoints::TextMessage

        property endpoint : Int32? = nil
      end
    end
  end
end
