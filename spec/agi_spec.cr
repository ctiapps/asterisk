require "./spec_helper"

describe Asterisk::AGI do
  # Testing basic actions
  describe "#basic_actions" do
    # it "should start FastAGI server on 127.0.0.1:9000" do
    #   agi = Asterisk::FastAGI.new host: "127.0.0.1", port: 9000
    #   # agi.start { |_| logger.info "Hello!" }
    #   agi.start { }
    #   sleep 0.01
    #   puts "started"
    #   agi.close
    # end
    #
    it "should execute AGI command 'command'" do
      # increase verbosity
      Asterisk.logger.level = Logger::DEBUG
      with_agi do |agi|
        agi.start do |agi|
          # agi.command %(ANSWER)
          agi.command %(verbose "this is a test" 3)
          # agi.command %(HANGUP)
          agi.logger.error ARGV.inspect
          started_at = Time.now
          agi.command %(EXEC Dial Local/answer@asterisk.cr,120,tT)
          agi.logger.error "ended in #{Time.now - started_at}"
        end

        # Trigger asterisk command
        Asterisk::Server.exec "originate Local/fastagi@asterisk.cr application Wait 120"

        sleep 120
      end
    end

  end
end
