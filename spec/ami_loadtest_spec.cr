require "./spec_helper"


describe Asterisk::AMI do
  Spec.before_each do
    # less noicy, please
    # Asterisk.logger.level = Logger::ERROR
    # Ensure that asterisk is up and running for each test
    unless Asterisk::Server.running?
      Asterisk::Server.start
      # let Asterisk boot
      sleep 3.seconds
    end
  end

  it "should correctly respond to all the invoked events within heavy loaded Asterisk" do
    fibers_count = 10
    fibers = Channel(Nil).new(fibers_count)
    fibers_count.times do |spawn_no|
      spawn_no_pretty = "0000#{spawn_no}"[-4,4]
      foobar = "foobar_#{spawn_no_pretty}"
      spawn do
        ami = Asterisk::AMI.new username: "asterisk.cr", secret: "asterisk.cr"
        # ami = Asterisk::AMI.new port: "15038", username: "88a26ad6ee3cff2cbb2fe3f49f7532e6", secret: "e47108082ec2bb74d83f7b3067b19396"
        ami.login

        50.times do |test_no|
          test_no_pretty = "0000#{test_no}"[-4,4]

          response = ami.send_action({"action" => "Ping"})
          response["ping"].should match /Pong/i

          foobar_value = %(#{spawn_no_pretty}-#{test_no_pretty}-#{Random::Secure.hex(8)})
          response = ami.send_action({"action" => "Setvar", "Variable" => foobar, "Value" => foobar_value})
          response.message.should match /Variable Set/i

          response = ami.send_action({"action" => "SIPpeers"}, expects_answer_before: 0.5)
          response["eventlist"].should match /^start$/i
          response.message.should match /list will follow/i

          response = ami.send_action({"action" => "Getvar", "Variable" => foobar})
          response.value.should eq(foobar_value)

          response = ami.send_action({"action" => "ListCommands"})
          response.data.has_key?("blindtransfer").should be_truthy

          # response = ami.send_action({"action" => "Queues"})
          # response["unknown"].should match /No queues/i

          response = ami.send_action({"action" => "Command", "command" => "agi show commands"})
          response.output.as(Array(String)).join("\n").should match /database del/im

          response = ami.send_action({"action" => "Command", "command" => "sip show peers"})
          response.output.as(Array(String)).join("\n").should match /test-account-905/im

          # short random pause after loop to randomize fibers data
          sleep 0.002 + rand(0.05)
        end # test loop
      rescue ex
        logger.error "AMI loadtest spec: #{ex.class}:#{ex.message} #{ex.backtrace}"
      ensure
        fibers.send nil
      end # spawn
    end

    fibers.receive
  end
end
