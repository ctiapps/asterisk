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

module Asterisk
  class ARI
    class Applications < Resources
      # Details of a Stasis application
      struct Application
        include JSON::Serializable

        # Name of this application
        property name : String

        # Id's for channels subscribed to.
        property channel_ids : Array(String)

        # Id's for bridges subscribed to.
        property bridge_ids : Array(String)

        # {tech}/{resource} for endpoints subscribed to.
        property endpoint_ids : Array(String)

        # Names of the devices subscribed to.
        property device_names : Array(String)

        # Event types sent to the application.
        property events_allowed : Hash(String, String | Bool | Int32 | Float32)

        # Event types not sent to the application.
        property events_disallowed : Hash(String, String | Bool | Int32 | Float32)
      end
    end
  end
end
