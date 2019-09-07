require "./spec_helper"

describe Asterisk::AsyncAGI do
  describe "#basic_actions" do
    it "should answer the call" do
      # increase verbosity
      Asterisk.logger.level = Logger::DEBUG
      agi = Asterisk::AsyncAGI::Server.new ami_username: "asterisk.cr", ami_secret: "asterisk.cr"
      agi.start do |agi|
        agi.verbose "This is a test", "3"
        agi.answer
        agi.say_alpha "Ping", "1"
        started_at = Time.utc
        agi.exec "Dial", destination: "Local/answer@asterisk.cr", timeout: 60, options: "tT"
        agi.logger.error "ended in #{Time.utc - started_at}"
        r = agi.hangup
        pp r
        sleep 1
        r = agi.answer
        pp r
      end

      # Trigger call to the Async AGI
      Asterisk::Server.exec "originate Local/asyncagi@asterisk.cr application Wait 120"
      sleep 20
    end
  end
end
