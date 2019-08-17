require "./spec_helper"

describe Asterisk::AGI do
  # Testing basic actions
  describe "#basic_actions" do
    it "should start FastAGI server on 127.0.0.1:4573, then stop it" do
      agi = Asterisk::FastAGI.new
      agi.start { }
      sleep 0.01
      agi.running?.should be_true
      agi.close
      sleep 0.01
      agi.closed?.should be_true
    end

    it "should answer the call" do
      # increase verbosity
      Asterisk.logger.level = Logger::DEBUG
      with_agi do |agi|
        agi.start do |agi|
          agi.verbose "This is a test", "3"
          # agi.answer
          sleep 12
          agi.answer
          # agi.say_alpha "Ping", "1"
          # started_at = Time.now
          # agi.exec "Dial", destination: "Local/answer@asterisk.cr", timeout: 60, options: "tT"
          # logger.error "Waiting!"
          sleep 15
          # agi.logger.error "ended in #{Time.now - started_at}"
          r = agi.hangup
          pp r
          sleep 1
          r = agi.answer
          pp r
        end

        # Trigger asterisk execute
        Asterisk::Server.exec "originate Local/fastagi@asterisk.cr application Wait 120"

        sleep 60
      end
    end
  end
end
