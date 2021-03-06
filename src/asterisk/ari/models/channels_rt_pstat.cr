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
    class Channels < Resources
      # A statistics of a RTP.
      struct RTPstat
        include JSON::Serializable

        # Number of packets transmitted.
        property txcount : Int32

        # Number of packets received.
        property rxcount : Int32

        # Jitter on transmitted packets.
        property txjitter : Float32? = nil

        # Jitter on received packets.
        property rxjitter : Float32? = nil

        # Maximum jitter on remote side.
        property remote_maxjitter : Float32? = nil

        # Minimum jitter on remote side.
        property remote_minjitter : Float32? = nil

        # Average jitter on remote side.
        property remote_normdevjitter : Float32? = nil

        # Standard deviation jitter on remote side.
        property remote_stdevjitter : Float32? = nil

        # Maximum jitter on local side.
        property local_maxjitter : Float32? = nil

        # Minimum jitter on local side.
        property local_minjitter : Float32? = nil

        # Average jitter on local side.
        property local_normdevjitter : Float32? = nil

        # Standard deviation jitter on local side.
        property local_stdevjitter : Float32? = nil

        # Number of transmitted packets lost.
        property txploss : Int32

        # Number of received packets lost.
        property rxploss : Int32

        # Maximum number of packets lost on remote side.
        property remote_maxrxploss : Float32? = nil

        # Minimum number of packets lost on remote side.
        property remote_minrxploss : Float32? = nil

        # Average number of packets lost on remote side.
        property remote_normdevrxploss : Float32? = nil

        # Standard deviation packets lost on remote side.
        property remote_stdevrxploss : Float32? = nil

        # Maximum number of packets lost on local side.
        property local_maxrxploss : Float32? = nil

        # Minimum number of packets lost on local side.
        property local_minrxploss : Float32? = nil

        # Average number of packets lost on local side.
        property local_normdevrxploss : Float32? = nil

        # Standard deviation packets lost on local side.
        property local_stdevrxploss : Float32? = nil

        # Total round trip time.
        property rtt : Float32? = nil

        # Maximum round trip time.
        property maxrtt : Float32? = nil

        # Minimum round trip time.
        property minrtt : Float32? = nil

        # Average round trip time.
        property normdevrtt : Float32? = nil

        # Standard deviation round trip time.
        property stdevrtt : Float32? = nil

        # Our SSRC.
        property local_ssrc : Int32

        # Their SSRC.
        property remote_ssrc : Int32

        # Number of octets transmitted.
        property txoctetcount : Int32

        # Number of octets received.
        property rxoctetcount : Int32

        # The Asterisk channel's unique ID that owns this instance.
        property channel_uniqueid : String
      end
    end
  end
end
