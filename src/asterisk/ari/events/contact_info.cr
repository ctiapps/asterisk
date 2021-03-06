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
      # Detailed information about a contact on an endpoint.
      struct ContactInfo < Event
        # The location of the contact.
        property uri : String

        # The current status of the contact.
        property contact_status : String

        # The Address of Record this contact belongs to.
        property aor : String

        # Current round trip time, in microseconds, for the contact.
        property roundtrip_usec : String? = nil
      end
    end
  end
end
