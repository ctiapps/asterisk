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
    class Recordings < Resources
      # List recordings that are complete.
      def list_stored : HTTP::Client::Response | Array(Recordings::StoredRecording)
        client.get "recordings/stored"
      end

      # Get a stored recording's details.
      #
      # Arguments:
      # - `recording_name` - the name of the recording.
      #   - Required: true,
      #   - Allow multiple (comma-separated list): false,
      #   ARI (http-client) related:
      #   - http request type: path,
      #   - param name: recordingName,
      #
      # API endpoint:
      # - method: get
      # - endpoint: /recordings/stored/{recordingName}
      #
      # Error responses:
      # - 404 - Recording not found
      def get_stored(recording_name : String) : HTTP::Client::Response | Recordings::StoredRecording
        response = client.get "recordings/stored/#{recording_name}"
      end

      # Delete a stored recording.
      #
      # Arguments:
      # - `recording_name` - the name of the recording.
      #   - Required: true,
      #   - Allow multiple (comma-separated list): false,
      #   ARI (http-client) related:
      #   - http request type: path,
      #   - param name: recordingName,
      #
      # API endpoint:
      # - method: delete
      # - endpoint: /recordings/stored/{recordingName}
      #
      # Error responses:
      # - 404 - Recording not found
      def delete_stored(recording_name : String)
        response = client.delete "recordings/stored/#{recording_name}"
      end

      # Get the file associated with the stored recording.
      #
      # Arguments:
      # - `recording_name` - the name of the recording.
      #   - Required: true,
      #   - Allow multiple (comma-separated list): false,
      #   ARI (http-client) related:
      #   - http request type: path,
      #   - param name: recordingName,
      #
      # API endpoint:
      # - method: get
      # - endpoint: /recordings/stored/{recordingName}/file
      #
      # Error responses:
      # - 403 - The recording file could not be opened
      # - 404 - Recording not found
      def get_stored_file(recording_name : String) : HTTP::Client::Response | Binary
        response = client.get "recordings/stored/#{recording_name}/file"
      end

      # Copy a stored recording.
      #
      # Arguments:
      # - `recording_name` - the name of the recording to copy.
      #   - Required: true,
      #   - Allow multiple (comma-separated list): false,
      #   ARI (http-client) related:
      #   - http request type: path,
      #   - param name: recordingName,
      #
      # - `destination_recording_name` - the destination name of the recording.
      #   - Required: true,
      #   - Allow multiple (comma-separated list): false,
      #   ARI (http-client) related:
      #   - http request type: query,
      #   - param name: destinationRecordingName,
      #
      # API endpoint:
      # - method: post
      # - endpoint: /recordings/stored/{recordingName}/copy
      #
      # Error responses:
      # - 404 - Recording not found
      # - 409 - A recording with the same name already exists on the system
      def copy_stored(recording_name : String, destination_recording_name : String) : HTTP::Client::Response | Recordings::StoredRecording
        params = HTTP::Params.encode({"destinationRecordingName" => destination_recording_name})
        response = client.post "recordings/stored/#{recording_name}/copy?" + params
      end

      # List live recordings.
      #
      # Arguments:
      # - `recording_name` - the name of the recording.
      #   - Required: true,
      #   - Allow multiple (comma-separated list): false,
      #   ARI (http-client) related:
      #   - http request type: path,
      #   - param name: recordingName,
      #
      # API endpoint:
      # - method: get
      # - endpoint: /recordings/live/{recordingName}
      #
      # Error responses:
      # - 404 - Recording not found
      def get_live(recording_name : String) : HTTP::Client::Response | Recordings::LiveRecording
        response = client.get "recordings/live/#{recording_name}"
      end

      # Stop a live recording and discard it.
      #
      # Arguments:
      # - `recording_name` - the name of the recording.
      #   - Required: true,
      #   - Allow multiple (comma-separated list): false,
      #   ARI (http-client) related:
      #   - http request type: path,
      #   - param name: recordingName,
      #
      # API endpoint:
      # - method: delete
      # - endpoint: /recordings/live/{recordingName}
      #
      # Error responses:
      # - 404 - Recording not found
      def cancel(recording_name : String)
        response = client.delete "recordings/live/#{recording_name}"
      end

      # Stop a live recording and store it.
      #
      # Arguments:
      # - `recording_name` - the name of the recording.
      #   - Required: true,
      #   - Allow multiple (comma-separated list): false,
      #   ARI (http-client) related:
      #   - http request type: path,
      #   - param name: recordingName,
      #
      # API endpoint:
      # - method: post
      # - endpoint: /recordings/live/{recordingName}/stop
      #
      # Error responses:
      # - 404 - Recording not found
      def stop(recording_name : String)
        response = client.post "recordings/live/#{recording_name}/stop"
      end

      # Pause a live recording.
      #
      # Arguments:
      # - `recording_name` - the name of the recording.
      #   - Required: true,
      #   - Allow multiple (comma-separated list): false,
      #   ARI (http-client) related:
      #   - http request type: path,
      #   - param name: recordingName,
      #
      # API endpoint:
      # - method: post
      # - endpoint: /recordings/live/{recordingName}/pause
      #
      # Error responses:
      # - 404 - Recording not found
      # - 409 - Recording not in session
      def pause(recording_name : String)
        response = client.post "recordings/live/#{recording_name}/pause"
      end

      # Unpause a live recording.
      #
      # Arguments:
      # - `recording_name` - the name of the recording.
      #   - Required: true,
      #   - Allow multiple (comma-separated list): false,
      #   ARI (http-client) related:
      #   - http request type: path,
      #   - param name: recordingName,
      #
      # API endpoint:
      # - method: delete
      # - endpoint: /recordings/live/{recordingName}/pause
      #
      # Error responses:
      # - 404 - Recording not found
      # - 409 - Recording not in session
      def unpause(recording_name : String)
        response = client.delete "recordings/live/#{recording_name}/pause"
      end

      # Mute a live recording.
      #
      # Arguments:
      # - `recording_name` - the name of the recording.
      #   - Required: true,
      #   - Allow multiple (comma-separated list): false,
      #   ARI (http-client) related:
      #   - http request type: path,
      #   - param name: recordingName,
      #
      # API endpoint:
      # - method: post
      # - endpoint: /recordings/live/{recordingName}/mute
      #
      # Error responses:
      # - 404 - Recording not found
      # - 409 - Recording not in session
      def mute(recording_name : String)
        response = client.post "recordings/live/#{recording_name}/mute"
      end

      # Unmute a live recording.
      #
      # Arguments:
      # - `recording_name` - the name of the recording.
      #   - Required: true,
      #   - Allow multiple (comma-separated list): false,
      #   ARI (http-client) related:
      #   - http request type: path,
      #   - param name: recordingName,
      #
      # API endpoint:
      # - method: delete
      # - endpoint: /recordings/live/{recordingName}/mute
      #
      # Error responses:
      # - 404 - Recording not found
      # - 409 - Recording not in session
      def unmute(recording_name : String)
        response = client.delete "recordings/live/#{recording_name}/mute"
      end
    end
  end
end
