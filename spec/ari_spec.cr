require "./spec_helper"

describe Asterisk::ARI do
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


  ##############################################################################
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


  ##############################################################################
  # Generated voice call should enter to the stasis app, then hangup request
  # will be invoked. ARI events should be triggered in followin sequence:
  # - StasisStart
  # - ChannelHangupRequest (when asterisk terminate the call)
  # - StasisEnd
  it "should receive ARI events" do
    ari_channel = Channel(String).new
    ari = Asterisk::ARI.new app: "asterisk.cr",
                            username: "asterisk.cr",
                            password: "asterisk.cr"

    ari.on_stasis_start           { ari_channel.send "StasisStart" }
    # ari.on_channel_hangup_request { ari_channel.send "ChannelHangupRequest" }
    ari.on_stasis_end             { ari_channel.send "StasisEnd" }
    ari.start

    # Trigger asterisk execute
    Asterisk::Server.exec "originate Local/ari@asterisk.cr application Wait 8"

    # Wait until call appear in stasis
    ari_channel.receive.should eq("StasisStart")

    # Request to terminate all the calls
    Asterisk::Server.exec "hangup request all"

    # sleep 0.25
    # ari_channel.receive.should eq("ChannelHangupRequest")

    sleep 0.25
    ari_channel.receive.should eq("StasisEnd")

    ari.close
  end


  ##############################################################################
  # Generated call should enter to the stasis app, then channl answer should
  # be requested and validated. Then hangup request will be invoked.
  # Following events are expected:
  # - StasisStart
  # - ChannelStateChange (after channel get answered)
  it "should execute ARI commands" do
    ari_channel = Channel(String).new

    ari = Asterisk::ARI.new app: "asterisk.cr",
                            username: "asterisk.cr",
                            password: "asterisk.cr"

    ari.on_stasis_start do |event|
      ari_channel.send "StasisStart"

      # channel = Asterisk::ARI::Channels.new(ari)
      # response = channel.answer channel_id: event.channel.id

      response = ari.channels.answer channel_id: event.channel.id
      # 2XX (normally it should be 204)
      (200..299).to_a.should contain(response.status_code)
    end

    ari.on_channel_state_change do |event|
      event.channel.state.should eq("Up")
      ari_channel.send "ChannelStateChange"
    end

    ari.on_stasis_end do
      ari_channel.send "StasisEnd"
    end

    ari.start

    # Trigger asterisk execute
    Asterisk::Server.exec "originate Local/ari@asterisk.cr application Wait 8"

    # Wait until call appear in stasis
    ari_channel.receive.should eq("StasisStart")

    # Wait until call state get changed (expected to be "Up" (answer)
    ari_channel.receive.should eq("ChannelStateChange")

    # request call hangup
    sleep 0.25
    Asterisk::Server.exec "hangup request all"
    ari_channel.receive
    sleep 0.25
    ari.close
  end


  ##############################################################################
  it "should trigger custom callbacks" do
    channel = Channel(String).new

    ari = Asterisk::ARI.new app: "asterisk.cr",
                            username: "asterisk.cr",
                            password: "asterisk.cr"

    ari.on_stasis_start do |event|
      channel.send event.channel.id
    end

    ari.on_channel_state_change do |event|
      logger.debug "ChannelStateChange event"
      event.channel.state.should eq("Up")
    end

    ari.start

    # Trigger asterisk execute
    Asterisk::Server.exec "originate Local/ari@asterisk.cr application Wait 8"

    # Wait until call appear in stasis
    channel_id = channel.receive

    event_name = UUID.random.to_s
    event_conditions = JSON.parse(%({"type": "ChannelStateChange",
                                     "channel": {"id": "#{channel_id}"}}))

    ari.on name: event_name, conditions: event_conditions do |event_json|
      logger.debug "Custom ChannelStateChange event"
      event = Asterisk::ARI::Events::ChannelStateChange.from_json(event_json)
      event.channel.state.should eq("Up")
    end

    ari.channels.answer channel_id: channel_id

    # # Wait until call state get changed (expected to be "Up" (answer)
    # ari_channel.receive.should eq("ChannelStateChange")

    sleep 0.25

    ari.remove_callback(event_name)

    # request call hangup
    Asterisk::Server.exec "hangup request all"
    sleep 0.25
    ari.close
  end
end
