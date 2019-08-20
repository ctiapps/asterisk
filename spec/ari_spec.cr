require "./spec_helper"

describe Asterisk::ARI do
  describe "#connection" do
    it "can connect with asterisk" do
      Asterisk.logger.level = Logger::DEBUG
      ari = Asterisk::ARI.new app: "asterisk.cr",
                              username: "asterisk.cr",
                              password: "asterisk.cr"
      ari.start

      # Trigger asterisk execute
      # Asterisk::Server.exec "originate Local/ari@asterisk.cr application Wait 120"

      sleep 60
    end
  end
end
