# Receiver basically id a pair actionid => channel and that let AMI
# listener method to respond to the send_action after it have enquire action
# channel is an single-use item, so all data will be vanished immediately
# after it get received
module Asterisk
  class AMI
    class Receiver
      WAIT_FOR_ANSWER = 0.001

      property actionid : ActionID?
      getter expects_answer_before : Float64
      getter logger : Logger

      getter response_channel : Channel::Unbuffered(Response)

      def initialize(@actionid : ActionID? = nil, @expects_answer_before : Float64 = 0.0, @logger : Logger = Asterisk.logger)
        # start with closed Receiver
        @response_channel = Channel::Unbuffered(Response).new
        response_channel.close
      end

      def get : Response
        response = begin
          @response_channel = Channel::Unbuffered(Response).new
          yield
          stop_after expects_answer_before
          response_channel.receive
        rescue Channel::ClosedError
          Response.new({"response" => "Error", "message" => "Timeout error while waiting for AMI response"})
        end
      ensure
        terminate!
        logger.debug "#{self.class}.get: received #{response.inspect}"
        response
      end

      private def stop_after(expects_answer_before : Float64)
        if expects_answer_before > 0.0
          spawn do
            started_at = Time.now
            while (Time.now - started_at).to_f < expects_answer_before
              sleep WAIT_FOR_ANSWER
            end
            terminate!
            logger.debug "#{self.class}.stop_after: terminated"
          end
        end
      end

      def send(data : Response)
        response_channel.send data
      end

      def waiting?
        ! response_channel.closed?
      end

      def terminate!
        @actionid = nil
        response_channel.close
        sleep 0.001
      end
    end
  end
end
