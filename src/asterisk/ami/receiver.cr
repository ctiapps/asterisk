# Receiver basically id a pair actionid => channel and that let AMI
# listener method to respond to the send_action after it have enquire action
# channel is an single-use item, so all data will be vanished immediately
# after it get received
module Asterisk
  class AMI
    class Receiver
      WAIT_FOR_ANSWER = 0.001

      getter actionid : ActionID?
      getter expects_answer_before : Float64 = 0.3
      getter logger : Logger

      getter response_channel : Channel::Unbuffered(Response)

      def initialize(@logger : Logger = Asterisk.logger)
        # start with closed Receiver
        @response_channel = Channel::Unbuffered(Response).new
        close
      end

      def send(data : Response | Event)
        response_channel.send data
      end

      def get(@actionid : ActionID, @expects_answer_before : Float64 = 0.3) : Response
        response = begin
          @response_channel = Channel::Unbuffered(Response).new
          yield
          close_after expects_answer_before
          response_channel.receive
        rescue Channel::ClosedError
          Response.new({"response" => "Error", "message" => "Timeout while waiting for AMI response", "expects_answer_before" => expects_answer_before.to_s})
        end
      ensure
        close
        logger.debug "#{self.class}.get: received #{response.inspect}"
        response
      end

      def closed?
        response_channel.closed?
      end

      # if Receiver instance is open, AMI runner might send response or event to
      # the response_channel
      def waiting?
        ! closed?
      end

      # close response_channel after given timeout
      private def close_after(timeout : Float64)
        timeout = 0.3 if timeout < 0.3
        spawn do
          started_at = Time.now
          while (Time.now - started_at).to_f < timeout
            sleep WAIT_FOR_ANSWER
          end
          close
        end
      end

      # close response_channel
      private def close
        return if closed?
        @actionid = nil
        response_channel.close
        sleep 0.001
      end
    end
  end
end
