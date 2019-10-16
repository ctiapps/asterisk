require "./spec_helper"

module Asterisk
  class ARI
    # TODO: open `def process_ws_message(json_data)`

    # getter for ARI handlers
    def handlers
      @handlers
    end
  end
end

describe Asterisk::ARI do
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

      # Set custom event handler for event "ChannelStateChange" and Channel's channel_id
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


  ##############################################################################
  # Often children methods or subclasses shall process event handlers for their
  # ID. For example, `on_stasis_start` could be used in a generic way, but also with
  # custom JSON filter on app_args (accuming that app_args is a JSON);
  # others could be used with instance filter: (i.e. channel handlers with filter on
  # `channel_id`; audio handlers with filter for `playback_id` or either both
  # `playback_id`/`channel_id` (or `bridge_id`).
  # That makes a need to support chained event handlers with option to remove
  # them.
  #
  # - generate a call and grab it by Stasis app
  # - set few event handlers
  # - answer call, so its state will get changed
  # - remove handler, terminate calls and ari
  it "should process all the event handlers in chain" do
    with_ari do |ami, ari|
      channel_id_ch = Channel(String).new
      handler_1     = Channel(Bool).new
      handler_2     = Channel(Bool).new
      handler_3     = Channel(Bool).new
      handler_4     = Channel(Bool).new
      handler_5     = Channel(Bool).new

      handlers = Array(String).new

      ari.on_stasis_start do |event|
        channel_id_ch.send event.channel.id
      end

      # prevent chanels freezing
      spawn do
        sleep 0.5.seconds
        channel_id_ch.send "failure"
      end

      generate_call

      # Wait until call appear in stasis
      channel_id = channel_id_ch.receive
      channel_id.should_not be "failure"

      h = ari.on_channel_state_change do |event|
        handler_1.send true if event.channel.state ==  "Up"
      end
      handlers.push h

      h = ari.on_channel_state_change do |event|
        handler_2.send true if event.channel.state ==  "Up"
      end
      handlers.push h

      h = ari.on_channel_state_change do |event|
        handler_3.send true if event.channel.state ==  "Up"
      end
      handlers.push h

      # last two also has a filter on channel_id
      h = ari.on_channel_state_change event_filter: JSON.parse(%({"channel": {"id": "#{channel_id}"}})) do |event|
        handler_4.send true if event.channel.state ==  "Up"
      end
      handlers.push h

      h = ari.on_channel_state_change event_filter: JSON.parse(%({"channel": {"id": "#{channel_id}"}})) do |event|
        handler_5.send true if event.channel.state ==  "Up"
      end
      handlers.push h

      # 1x on_stasis_start and 5x on_channel_state_change
      ari.handlers.size.should eq 6

      # Get call answered, so custom handler will be executed in a while
      ari.channels.answer channel_id: channel_id

      # prevent chanels freezing
      spawn do
        sleep 0.5.seconds
        handler_1.send false
        handler_2.send false
        handler_3.send false
        handler_4.send false
        handler_5.send false
      end

      # Wait until call state get changed (answered, expected to be "Up")
      handler_1.receive.should be_true
      handler_2.receive.should be_true
      handler_3.receive.should be_true
      handler_4.receive.should be_true
      handler_5.receive.should be_true

      handlers.each do |handler_id|
        ari.remove_handler(handler_id)
      end

      # After remove, only one handler keep remaining (on_stasis_start)
      ari.handlers.size.should eq 1
    end
  end
end
