require "./spec_helper"

describe Asterisk::ARI do
  describe "#connection" do
    it "should correctly process JSON for ARI event" do
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
      event.type.should eq("StasisStart")
    end

    # After ari.start, it will connect with asterisk as ari app, it can be
    # discovered calling "ari show apps" from asterisk command line:
    #
    # ❯ asterisk -rx "ari show apps"
    # Application Name
    # =========================
    # asterisk.cr
    it "can connect with asterisk" do
      # Asterisk.logger.level = Logger:DEBUG
      ari = Asterisk::ARI.new app: "asterisk.cr",
                              username: "asterisk.cr",
                              password: "asterisk.cr"
      ari.start
      sleep 0.1.seconds
      data = Asterisk::Server.exec "ari show apps"
      data.should match(/asterisk\.cr/m)
      ari.close
    end

    # Call will be generated and should enter to the stasis, then hangup
    # request will be sent. ARI events should be triggered in following
    # sequence:
    # - StasisStart
    # - ChannelHangupRequest
    # - StasisEnd
    it "should receive ARI events" do
      ari_channel = Channel(String).new
      ari = Asterisk::ARI.new app: "asterisk.cr",
                              username: "asterisk.cr",
                              password: "asterisk.cr"

      ari.on_stasis_start           { ari_channel.send "StasisStart" }
      ari.on_channel_hangup_request { ari_channel.send "ChannelHangupRequest" }
      ari.on_stasis_end             { ari_channel.send "StasisEnd" }
      ari.start

      # Trigger asterisk execute
      Asterisk::Server.exec "originate Local/ari@asterisk.cr application Wait 8"
      ari_channel.receive.should eq("StasisStart")
      Asterisk::Server.exec "hangup request all"
      sleep 0.25
      ari_channel.receive.should eq("ChannelHangupRequest")
      sleep 0.25
      ari_channel.receive.should eq("StasisEnd")
      ari.close
    end
    #
    # it "should execute ARI commands" do
    #   ari_channel = Channel(String).new
    #   stasis_channel : Asterisk::ARI::Channels::Channel? = nil
    #   stasis_channel_id = nil
    #
    #   ari = Asterisk::ARI.new app: "asterisk.cr",
    #                           username: "asterisk.cr",
    #                           password: "asterisk.cr"
    #
    #   ari.on_stasis_end   { ari_channel.send "StasisEnd" }
    #   ari.on_stasis_start do |event|
    #     stasis_channel    = event.channel
    #     stasis_channel_id = event.channel.id
    #     ari_channel.send "StasisStart"
    #   end
    #   ari.start
    #   # Asterisk::ARI.ari = ari
    #
    #   # Trigger asterisk execute
    #   Asterisk::Server.exec "originate Local/ari@asterisk.cr application Wait 8"
    #   ari_channel.receive.should eq("StasisStart")
    #
    #   if stasis_channel
    #     channel_id = stasis_channel.not_nil!.id
    #     puts
    #     puts "answering call for #{channel_id}"
    #     Asterisk::ARI::Channels.answer channel_id: channel_id
    #   end
    #
    #   sleep 5
    #
    #   Asterisk::Server.exec "hangup request all"
    #   ari_channel.receive
    #   sleep 0.2
    #   ari.close
    # end

  end
end
