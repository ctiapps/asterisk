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

module Asterisk
  class ARI
    class Playbacks < Resources
      # Get a playback's details.
      #
      # Arguments:
      # - `playback_id` - playback's id.
      #   - Required: true,
      #   - Allow multiple (comma-separated list): false,
      #   ARI (http-client) related:
      #   - http request type: path,
      #   - param name: playbackId,
      #
      # API endpoint:
      # - method: get
      # - endpoint: /playbacks/{playbackId}
      #
      # Error responses:
      # - 404 - The playback cannot be found
      def get(playback_id : String) : HTTP::Client::Response | Playbacks::Playback
        response = client.get "playbacks/#{playback_id}"
      end

      # Stop a playback.
      #
      # Arguments:
      # - `playback_id` - playback's id.
      #   - Required: true,
      #   - Allow multiple (comma-separated list): false,
      #   ARI (http-client) related:
      #   - http request type: path,
      #   - param name: playbackId,
      #
      # API endpoint:
      # - method: delete
      # - endpoint: /playbacks/{playbackId}
      #
      # Error responses:
      # - 404 - The playback cannot be found
      def stop(playback_id : String)
        response = client.delete "playbacks/#{playback_id}"
      end

      # Control a playback.
      #
      # Arguments:
      # - `playback_id` - playback's id.
      #   - Required: true,
      #   - Allow multiple (comma-separated list): false,
      #   ARI (http-client) related:
      #   - http request type: path,
      #   - param name: playbackId,
      #
      # - `operation` - operation to perform on the playback.
      #   - Required: true,
      #   - Allow multiple (comma-separated list): false,
      #   ARI (http-client) related:
      #   - http request type: query,
      #   - param name: operation,
      #
      # API endpoint:
      # - method: post
      # - endpoint: /playbacks/{playbackId}/control
      #
      # Error responses:
      # - 400 - The provided operation parameter was invalid
      # - 404 - The playback cannot be found
      # - 409 - The operation cannot be performed in the playback's current state
      def control(playback_id : String, operation : String)
        params = HTTP::Params.encode({"operation" => operation})
        response = client.post "playbacks/#{playback_id}/control?" + params
      end
    end
  end
end
