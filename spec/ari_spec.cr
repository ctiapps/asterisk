require "./spec_helper"

describe Asterisk::ARI do
  describe "#connection" do
    it "can process generated events" do
      message = %({
          "type": "StasisStart",
          "timestamp": "2019-08-27T10:43:02.170+0200",
          "args": [],
          "channel": {
            "id": "1566895382.3",
            "name": "Local/ari@asterisk.cr-00000001;2",
            "state": "Ring",
            "caller": {
              "name": "",
              "number": ""
            },
            "connected": {
              "name": "",
              "number": ""
            },
            "accountcode": "",
            "dialplan": {
              "context": "asterisk.cr",
              "exten": "ari",
              "priority": 2,
              "app_name": "Stasis",
              "app_data": "asterisk.cr"
            },
            "creationtime": "2019-08-27T10:43:02.166+0200",
            "language": "en"
          },
          "asterisk_id": "de:2e:40:5d:d0:1f",
          "application": "asterisk.cr"
        })
      event = Asterisk::ARI::Events::StasisStart.from_json(message)
      # pp event
    end
    it "can connect with asterisk" do
      Asterisk.logger.level = Logger::DEBUG
      ari = Asterisk::ARI.new app: "asterisk.cr",
                              username: "asterisk.cr",
                              password: "asterisk.cr"

      ari.on_stasis_start do |event|
        pp event
      end

      ari.start
      # pp Asterisk::ARI::Events.events
      # pp Asterisk::ARI.list

      # Trigger asterisk execute
      Asterisk::Server.exec "originate Local/ari@asterisk.cr application Wait 8"

      sleep 8.5
      Asterisk::Server.exec "hangup request all"
      sleep 1
      ari.close
      sleep 1
    end
  end
end
