require "./spec_helper"

describe Asterisk::AMI do
  it "should correctly respond to all the invoked events within heavy loaded Asterisk" do
    # # less noicy, please
    # Asterisk.logger.level = Logger::ERROR

    # consider increasing expects_answer_before timeout for higher value of
    # fibers_count, CPU load could be high
    expects_answer_before = 1.0

    # how many parallel AMI connections should be tested
    fibers_count = 10
    fibers = Channel(Nil).new(fibers_count)

    # how much loops of tests to execute
    test_loops_count = 50

    fibers_count.times do |spawn_no|
      spawn_no_pretty = "0000#{spawn_no}"[-4, 4]
      foobar = "foobar_#{spawn_no_pretty}"
      spawn do
        with_ami(username: "asterisk.cr", secret: "asterisk.cr") do |ami|
          test_loops_count.times do |test_no|
            test_no_pretty = "0000#{test_no}"[-4, 4]

            actionid = UUID.random.to_s
            response = ami.send_action({"action" => "Ping", "actionid" => actionid})
            response.success?.should be_true
            response.actionid.should eq(actionid)
            response["ping"].should match /Pong/i

            actionid = UUID.random.to_s
            foobar_value = %(#{spawn_no_pretty}-#{test_no_pretty}-#{UUID.random.to_s})
            response = ami.send_action({"action" => "Setvar", "Variable" => foobar, "Value" => foobar_value, "actionid" => actionid})
            response.success?.should be_true
            response.actionid.should eq(actionid)
            response.message.should match /Variable Set/i

            actionid = UUID.random.to_s
            response = ami.send_action({"action" => "SIPpeers", "actionid" => actionid}, expects_answer_before: expects_answer_before)
            response.success?.should be_true
            response.actionid.should eq(actionid)
            response["eventlist"].should match /^start$/i
            response.message.should match /list will follow/i

            actionid = UUID.random.to_s
            response = ami.send_action({"action" => "Getvar", "Variable" => foobar, "actionid" => actionid})
            response.success?.should be_true
            response.actionid.should eq(actionid)
            response.value.should eq(foobar_value)

            actionid = UUID.random.to_s
            response = ami.send_action({"action" => "ListCommands", "actionid" => actionid})
            response.success?.should be_true
            response.actionid.should eq(actionid)
            response.data.has_key?("blindtransfer").should be_truthy
            response.success?.should be_true

            # actionid = UUID.random.to_s
            # response = ami.send_action({"action" => "Queues", "actionid" => actionid})
            # response.actionid?.should be_falsey
            # response["unknown"].should match /No queues/i

            actionid = UUID.random.to_s
            response = ami.send_action({"action" => "Command", "command" => "agi show commands", "actionid" => actionid})
            response.actionid.should eq(actionid)
            response.output.as(Array(String)).join("\n").should match /database del/im

            actionid = UUID.random.to_s
            response = ami.send_action({"action" => "Command", "command" => "sip show peers", "actionid" => actionid})
            response.actionid.should eq(actionid)
            response.output.as(Array(String)).join("\n").should match /test-account-905/im

            # short random pause after loop to randomize fibers data
            sleep rand(0.05)
          rescue ex
            puts %(\n\nAMI loadtest spec: #{ex.class}:#{ex.message}\n#{ex.backtrace.pretty_inspect}\n\nLatest response: #{response.inspect rescue "-- n/a ---"}\n\n)
            break
          end # test loop

        ensure
          fibers.send nil
        end # with_ami
      end   # spawn
    end

    fibers.receive
  end

  # This test is useful in order to validate how Asterisk AsyncAGI will be
  # working
  it "should correctly respond to actions send by different fibers using shared AMI connection" do
    # # less noicy, please
    # Asterisk.logger.level = Logger::DEBUG

    # consider increasing expects_answer_before timeout for higher value of
    # fibers_count, CPU load could be high
    expects_answer_before = 1.0

    # how many parallel fibers will be used.
    fibers_count = 5
    fibers = Channel(Nil).new(fibers_count)

    # how much loops of tests to execute
    test_loops_count = 50

    with_ami(username: "asterisk.cr", secret: "asterisk.cr") do |ami|
      fibers_count.times do |spawn_no|
        spawn_no_pretty = "0000#{spawn_no}"[-4, 4]
        foobar = "foobar_#{spawn_no_pretty}"
        spawn do
          test_loops_count.times do |test_no|
            test_no_pretty = "0000#{test_no}"[-4, 4]

            actionid = UUID.random.to_s
            response = ami.send_action({"action" => "Ping", "actionid" => actionid})
            response.success?.should be_true
            response.actionid.should eq(actionid)
            response["ping"].should match /Pong/i

            actionid = UUID.random.to_s
            foobar_value = %(#{spawn_no_pretty}-#{test_no_pretty}-#{UUID.random.to_s})
            response = ami.send_action({"action" => "Setvar", "Variable" => foobar, "Value" => foobar_value, "actionid" => actionid})
            response.success?.should be_true
            response.actionid.should eq(actionid)
            response.message.should match /Variable Set/i

            actionid = UUID.random.to_s
            response = ami.send_action({"action" => "SIPpeers", "actionid" => actionid}, expects_answer_before: expects_answer_before)
            response.success?.should be_true
            response.actionid.should eq(actionid)
            response["eventlist"].should match /^start$/i
            response.message.should match /list will follow/i

            actionid = UUID.random.to_s
            response = ami.send_action({"action" => "Getvar", "Variable" => foobar, "actionid" => actionid})
            response.success?.should be_true
            response.actionid.should eq(actionid)
            response.value.should eq(foobar_value)

            actionid = UUID.random.to_s
            response = ami.send_action({"action" => "ListCommands", "actionid" => actionid})
            response.success?.should be_true
            response.actionid.should eq(actionid)
            response.data.has_key?("blindtransfer").should be_truthy
            response.success?.should be_true

            # actionid = UUID.random.to_s
            # response = ami.send_action({"action" => "Queues", "actionid" => actionid})
            # response.actionid?.should be_falsey
            # response["unknown"].should match /No queues/i

            actionid = UUID.random.to_s
            response = ami.send_action({"action" => "Command", "command" => "agi show commands", "actionid" => actionid})
            response.actionid.should eq(actionid)
            response.output.as(Array(String)).join("\n").should match /database del/im

            actionid = UUID.random.to_s
            response = ami.send_action({"action" => "Command", "command" => "sip show peers", "actionid" => actionid})
            response.actionid.should eq(actionid)
            response.output.as(Array(String)).join("\n").should match /test-account-905/im

            # short random pause after loop to randomize fibers data
            sleep rand(0.05)
          rescue ex
            puts %(\n\nAMI loadtest spec: #{ex.class}:#{ex.message}\n#{ex.backtrace.pretty_inspect}\n\nLatest response: #{response.inspect rescue "-- n/a ---"}\n\n)
            break
          end # test loop
        ensure
          fibers.send nil
        end # spawn

        fibers.receive
        sleep 5.seconds
      end # with_ami

    end
  end
end
