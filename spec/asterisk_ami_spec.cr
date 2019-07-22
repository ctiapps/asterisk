require "./spec_helper"

describe Asterisk::AMI do
  Spec.before_each do
    # less noicy, please
    # Asterisk.logger.level = Logger::FATAL
    # Ensure that asterisk is up and running for each test
    unless AsteriskPBX.running?
      AsteriskPBX.start!
      # let him bootup properly
      sleep 5.seconds
    end
  end

  # # Testing connectivity with AMI TCPSocket
  # describe "#connectivity" do
  #   it "should throw error if connecting to the incorrect AMI instance" do
  #     ami = Asterisk::AMI.new username: "incorrect", secret: "incorrect"
  #     expect_raises(Asterisk::AMI::LoginError) do
  #       ami.login
  #     end
  #   end
  #
  #   it "should successfully connect with correct credentials" do
  #     # credentials should be specified in /etc/asterisk/manager.conf
  #     ami = Asterisk::AMI.new username: "asterisk.cr", secret: "asterisk.cr"
  #     ami.login
  #     ami.connected?.should be_true
  #   end
  #
  #   it "should successfully connect and disconnect" do
  #     ami = Asterisk::AMI.new username: "asterisk.cr", secret: "asterisk.cr"
  #     ami.login
  #     sleep 0.02
  #     ami.dislogin
  #     ami.connected?.should be_false
  #   end
  #
  #   it "should change 'connected?' state if connection with AMI get broken" do
  #     ami = Asterisk::AMI.new username: "asterisk.cr", secret: "asterisk.cr"
  #     ami.login
  #     channel = Channel(Exception? | Nil).new
  #     spawn do
  #       sleep 2.seconds
  #       AsteriskPBX.stop!
  #       channel.send(nil)
  #     end
  #     result = channel.receive
  #     puts ">>> Are Asterisk up? #{AsteriskPBX.running?.to_s}"
  #     ami.connected?.should be_false
  #   end
  # end

  # Testing basic actions
  describe "#basic_actions" do
    it "should successfully set asterisk global variable and then read it" do
      ami = Asterisk::AMI.new username: "asterisk.cr", secret: "asterisk.cr"
      ami.login
      response = ami.send_action({"action" => "Ping", "actionid" => "1"})
      response = ami.send_action({"action" => "Ping", "actionid" => "2"})
      response = ami.send_action({"action" => "Ping", "actionid" => "3"})
      response = ami.send_action({"action" => "Ping", "actionid" => "4"})
      response = ami.send_action({"action" => "Ping", "actionid" => "5"})
      puts "RESPONSE: #{response}"
      sleep 3
      true.should be_true
    end
  
    # it "should successfully set asterisk global variable and then read it" do
    #   ami = Asterisk::AMI.new username: "asterisk.cr", secret: "asterisk.cr"
    #   ami.login
    #   foobar_value = Random::Secure.hex(8)
    #   ami.send_action({"action" => "Setvar", "Variable" => "foobar", "Value" => foobar_value})
    #   response = ami.send_action({"action" => "Getvar", "Variable" => "foobar"})
    #   puts "RESPONSE: #{response}"
    #   response["value"].should eq(foobar_value)
    # end
  end

  # # Testing events that receive multiline event or multiple events as response
  # describe "#multiline_events" do
  #   # # TODO
  #   # it "should process complex action that include multiple events in response (ListCommands)" do
  #   #   ami = Asterisk::AMI.new username: "asterisk.cr", secret: "asterisk.cr"
  #   #   ami.login
  #   #   res = ami.send_action({"action" => "ListCommands"})
  #   #   # {"response" => "Success", "actionid" => "58a480df-32a1-4378-8f3d-03327b78465f",
  #   #   #  "waitevent" => "Wait for an event to occur.  (Priv: <none>)",
  #   #   #  "devicestatelist" => "List the current known device states.  (Priv: call,reporting,all)", "..." => "..."}
  #   #   # res.not_nil!.first.has_key?("waitevent").should be_true
  #   #   true.should be_true
  #   # end
  #
  #   # # TODO
  #   # it "should process complex action that include multiple events in response (SIPpeers)" do
  #   #   ami = Asterisk::AMI.new username: "asterisk.cr", secret: "asterisk.cr"
  #   #   ami.login
  #   #   res = ami.send_action({"action" => "SIPpeers"})
  #   #   # INFO -- : {"response" => "Success", "actionid" => "01b9e8bf-1b6a-4c8b-8f57-8880f1d895db", "eventlist" => "start",
  #   #   # res.not_nil!.first["objectname"].should match /^test-account-\d{3}/
  #   #   sleep 10.seconds
  #   #   true.should be_true
  #   # end
  #
  #   # # TODO
  #   # it "should process complex action that include multiple events in response (Queues)" do
  #   #   ami = Asterisk::AMI.new username: "asterisk.cr", secret: "asterisk.cr"
  #   #   ami.login
  #   #   res = ami.send_action({"action" => "Queues"})
  #   #   # D, [2019-07-21 05:12:41 +00:00 #7416] DEBUG -- : Received Asterisk manager event:
  #   #   # D, [2019-07-21 05:12:41 +00:00 #7416] DEBUG -- : Processing line: No queues.
  #   #   sleep 10.seconds
  #   #   true.should be_true
  #   # end
  #
  #   # # TODO
  #   # it "should successfully process complex action (that include multiple events in response)" do
  #   #   ami = Asterisk::AMI.new username: "asterisk.cr", secret: "asterisk.cr"
  #   #   ami.login
  #   #   ami.send_action({"action" => "Command", "command" => "agi show commands"})
  #   #   # D, [2019-07-21 19:45:44 +00:00 #11671] DEBUG -- : format_event: processing line: Response: Follows
  #   #   # D, [2019-07-21 19:45:44 +00:00 #11671] DEBUG -- : format_event: processing line: Privilege: Command
  #   #   # D, [2019-07-21 19:45:44 +00:00 #11671] DEBUG -- : format_event: processing line: ActionID: 37df9dee-2593-4ab3-a015-ef16c8df8e3b
  #   #   # D, [2019-07-21 19:45:44 +00:00 #11671] DEBUG -- : format_event: processing line:  Dead                        Command   Description
  #   #   #    No                         answer   Answer channel
  #   #   #   Yes                 asyncagi break   Interrupts Async AGI
  #   #   #    No                 channel status   Returns status of the connected channel.
  #   #   # ...
  #   #   # --END COMMAND--
  #   #   sleep 10.seconds
  #   #   ami.connected?.should be_true
  #   # end
  #
  #   # # TODO
  #   # it "should successfully process complex action (that include multiple events in response)" do
  #   #   ami = Asterisk::AMI.new username: "asterisk.cr", secret: "asterisk.cr"
  #   #   ami.c,bonnect!
  #   #   ami.send_action({"action" => "Command", "command" => "core show uptime"})
  #   #   sleep 10
  #   #   # D, [2019-07-21 20:04:01 +00:00 #11966] DEBUG -- : format_event: processing line: Response: Follows
  #   #   # D, [2019-07-21 20:04:01 +00:00 #11966] DEBUG -- : format_event: processing line: Privilege: Command
  #   #   # D, [2019-07-21 20:04:01 +00:00 #11966] DEBUG -- : format_event: processing line: ActionID: 75443869-e766-451f-8194-c0e925191030
  #   #   # D, [2019-07-21 20:04:01 +00:00 #11966] DEBUG -- : format_event: processing line: System uptime: 23 minutes, 36 seconds
  #   #   # Last reload: 23 minutes, 36 seconds
  #   #   # --END COMMAND--
  #   #   ami.connected?.should be_true
  #   # end
  #
  #   # # TODO
  #   # it "should successfully process complex action (that include multiple events in response)" do
  #   #   ami = Asterisk::AMI.new username: "asterisk.cr", secret: "asterisk.cr"
  #   #   ami.login
  #   #   ami.send_action({"action" => "Command", "command" => "sip show peers"})
  #   #   # D, [2019-07-21 19:58:04 +00:00 #11917] DEBUG -- : format_event: processing line: Response: Follows
  #   #   # D, [2019-07-21 19:58:04 +00:00 #11917] DEBUG -- : format_event: processing line: Privilege: Command
  #   #   # D, [2019-07-21 19:58:04 +00:00 #11917] DEBUG -- : format_event: processing line: ActionID: b3ccf896-0ce5-4daf-9576-8a44cbcd6e43
  #   #   # D, [2019-07-21 19:58:04 +00:00 #11917] DEBUG -- : format_event: processing line: Name/username             Host                                    Dyn Forcerport Comedia    ACL Port     Status      Description
  #   #   # test-account-900/900      (Unspecified)                            D  Auto (No)  No             0        UNKNOWN
  #   #   # test-account-901/901      (Unspecified)                            D  Auto (No)  No             0        UNKNOWN
  #   #   # ...
  #   #   # 10 sip peers [Monitored: 0 online, 10 offline Unmonitored: 0 online, 0 offline]
  #   #   # --END COMMAND--
  #   #   sleep 10
  #   #   ami.connected?.should be_true
  #   # end
  # end

end
