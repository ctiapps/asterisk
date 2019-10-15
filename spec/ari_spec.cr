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
  it "ARI client should connect to Asterisk" do
    # Asterisk.logger.level = Logger:DEBUG
    ari = Asterisk::ARI.new app: "asterisk.cr",
                            username: "asterisk.cr",
                            password: "asterisk.cr"
    ari.start
    sleep 0.05.seconds
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
    ari = Asterisk::ARI.new app: "asterisk.cr",
                            username: "asterisk.cr",
                            password: "asterisk.cr"

    start_ch  = Channel(Bool).new
    hangup_ch = Channel(Bool).new
    end_ch    = Channel(Bool).new

    ari.on_stasis_start do
      start_ch.send true
    end

    ari.on_channel_hangup_request do
      hangup_ch.send true
    end

    ari.on_stasis_end do
      end_ch.send true
    end

    ari.start

    # Trigger asterisk execute
    Asterisk::Server.exec "originate Local/ari@asterisk.cr application Wait 1"

    # prevent chanels freezing
    spawn do
      sleep 0.5.seconds
      start_ch.send  false
      hangup_ch.send false
      end_ch.send    false
    end

    # Wait until call appear in stasis
    start_ch.receive.should be_true

    # Request to terminate all the calls
    Asterisk::Server.exec "hangup request all"

    hangup_ch.receive.should be_true
    end_ch.receive.should be_true

    ari.close
  end


  ##############################################################################
  # Generated call should enter to the stasis app, then channel answer should
  # be requested and validated. Then hangup request will be invoked.
  # Following events are expected:
  # - StasisStart
  # - ChannelStateChange (after channel get answered)
  it "should execute ARI commands" do
    ari = Asterisk::ARI.new app: "asterisk.cr",
                            username: "asterisk.cr",
                            password: "asterisk.cr"

    start_ch  = Channel(Bool).new
    answer_ch = Channel(Bool).new
    end_ch    = Channel(Bool).new

    ari.on_stasis_start do |event|
      response = ari.channels.answer channel_id: event.channel.id
      # 2XX (normally it should be 204)
      response.success?.should be_true

      start_ch.send true
    end

    ari.on_channel_state_change do |event|
      answer_ch.send true if event.channel.state == "Up"
    end

    ari.on_stasis_end do
      end_ch.send true
    end

    ari.start

    # Trigger asterisk execute
    Asterisk::Server.exec "originate Local/ari@asterisk.cr application Wait 1"

    # prevent chanels freezing
    spawn do
      sleep 0.5.seconds
      start_ch.send  false
      answer_ch.send false
      end_ch.send    false
    end

    # Wait until call appear in stasis
    start_ch.receive.should be_true

    # Wait until call state get changed (expected to be "Up" (answer)
    answer_ch.receive.should be_true

    # request call hangup
    Asterisk::Server.exec "hangup request all"

    end_ch.receive.should be_true
    ari.close
  end


  ##############################################################################
  # - generate a call and grab it by Stasis app
  # - set custom event handler (on channel state change)
  # - answer call, so its state will get changed
  # - remove handler, terminate calls and ari
  it "should set custom events handler and process events" do
    with_ari do |ami, ari|
      channel_id_ch = Channel(String).new
      answer_ch     = Channel(Bool).new

      ari.on_stasis_start do |event|
        channel_id_ch.send event.channel.id
      end

      generate_call

      # prevent chanels freezing
      spawn do
        sleep 0.5.seconds
        channel_id_ch.send "failure"
        answer_ch.send     false
      end

      # Wait until call appear in stasis
      channel_id = channel_id_ch.receive
      channel_id.should_not be "failure"

      # Set custom event handler for event "ChannelStateChange" and channel
      # channel_id
      event_filter = JSON.parse(%({"type": "ChannelStateChange",
                                   "channel": {"id": "#{channel_id}"}}))

      handler_id = ari.on event_filter: event_filter do |event_json|
        event = Asterisk::ARI::Events::ChannelStateChange.from_json(event_json)
        if event.channel.state ==  "Up"
          answer_ch.send true
        end
      end

      # Get call answered, so custom handler will be executed in a while
      ari.channels.answer channel_id: channel_id

      # Wait until call state get changed (answered, expected to be "Up")
      answer_ch.receive.should be_true

      ari.remove_handler(handler_id)
    end
  end
end
