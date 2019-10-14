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

module Asterisk
  class ARI
    class Mailboxes < Resources
      # Represents the state of a mailbox.
      struct Mailbox
        include JSON::Serializable

        # Name of the mailbox.
        property name : String

        # Count of old messages in the mailbox.
        property old_messages : Int32

        # Count of new messages in the mailbox.
        property new_messages : Int32
      end
    end
  end
end
