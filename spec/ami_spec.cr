require "./spec_helper"

describe Asterisk::AMI do
  # Testing basic actions
  describe "#basic_actions" do
    it "after login, client should set ami_version, asterisk_version and asterisk_platform" do
      with_ami do |ami|
        ami.ami_version.should_not be_nil
        ami.asterisk_version.should_not be_nil
        ami.asterisk_platform.should_not be_nil
      end
    end

    it "should respond with 'Pong' to action 'ping'" do
      with_ami do |ami|
        10.times do |i|
          actionid = Random::Secure.hex(8)
          response = ami.send_action({"action" => "Ping", "actionid" => actionid})
          response.success?.should be_true
          response.actionid.should eq(actionid)
          response["ping"].should match /Pong/i
        end
      end
    end

    it "should successfully set and read asterisk dialplan global variable" do
      with_ami do |ami|
        # set
        actionid = Random::Secure.hex(8)
        foobar_value = Random::Secure.hex(8)
        response = ami.send_action({"action" => "Setvar", "Variable" => "foobar", "Value" => foobar_value, "actionid" => actionid})
        response.success?.should be_true
        response.actionid.should eq(actionid)
        response["message"].should match /Variable Set$/i

        # read
        actionid = Random::Secure.hex(8)
        response = ami.send_action({"action" => "Getvar", "Variable" => "foobar", "actionid" => actionid})
        response.success?.should be_true
        response.actionid.should eq(actionid)
        response["variable"].should eq("foobar")
        response.value.should eq(foobar_value)
      end
    end
  end

  # Testing actions that receive multiline event or multiple events as a response
  describe "#multiline_events" do
    it "should process action that contain multiple lines in response (ListCommands)" do
      with_ami do |ami|
        actionid = Random::Secure.hex(8)
        response = ami.send_action({"action" => "ListCommands", "actionid" => actionid})
        response.actionid.should eq(actionid)
        response["waitevent"]?.should be_truthy
      end
    end

    it "should process complex action that include multiple events in response (Queues)" do
      with_ami do |ami|
        response = ami.send_action({"action" => "Queues"})
        # D, [2019-07-21 05:12:41 +00:00 #7416] DEBUG -- : Received Asterisk manager event:
        # D, [2019-07-21 05:12:41 +00:00 #7416] DEBUG -- : Processing line: No queues.
        response["unknown"].should match /No queues/i
      end
    end

    it "should process complex action that include multiple events in response (SIPpeers)" do
      with_ami do |ami|
        # # increase verbosity
        # Asterisk.logger.level = Logger::DEBUG
        actionid = Random::Secure.hex(8)
        response = ami.send_action({"action" => "SIPpeers", "actionid" => actionid})
        # sleep 3.seconds
        logger.debug response
        # INFO -- : {"response" => "Success", "actionid" => "01b9e8bf-1b6a-4c8b-8f57-8880f1d895db", "eventlist" => "start",
        # res.not_nil!.first["objectname"].should match /^test-account-\d{3}/
        response.success?.should be_true
        response.actionid.should eq(actionid)
        response["eventlist"].should match /start/i
        response["message"].should match /follow/i
        # Asterisk.logger.level = Logger::ERROR
      end
    end

    it "should process complex action that include multiple events in response (IAXpeers)" do
      with_ami do |ami|
        actionid = Random::Secure.hex(8)
        response = ami.send_action({"action" => "IAXpeers", "actionid" => actionid})
        response.success?.should be_true
        response.actionid.should eq(actionid)
        response["eventlist"].should match /start/i
        response["message"].should match /follow/i
      end
    end

    it "should successfully process asterisk command 'agi show commands'" do
      with_ami do |ami|
        actionid = Random::Secure.hex(8)
        response = ami.send_action({"action" => "Command", "command" => "agi show commands", "actionid" => actionid})
        response.actionid.should eq(actionid)
        response.output.as(Array(String)).join("\n").should match /database del/im
      end
    end

    it "should successfully process asterisk command 'core show uptime'" do
      with_ami do |ami|
        actionid = Random::Secure.hex(8)
        response = ami.send_action({"action" => "Command", "command" => "core show uptime", "actionid" => actionid})
        # D, [2019-07-21 20:04:01 +00:00 #11966] DEBUG -- : format_event: processing line: Response: Follows
        # D, [2019-07-21 20:04:01 +00:00 #11966] DEBUG -- : format_event: processing line: Privilege: Command
        # D, [2019-07-21 20:04:01 +00:00 #11966] DEBUG -- : format_event: processing line: ActionID: 75443869-e766-451f-8194-c0e925191030
        # D, [2019-07-21 20:04:01 +00:00 #11966] DEBUG -- : format_event: processing line: System uptime: 23 minutes, 36 seconds
        # Last reload: 23 minutes, 36 seconds
        # --END COMMAND--
        response.output.as(Array(String)).join("\n") =~ /(?|uptime: (.+)|reload: (.+))/i
        # 23 hours, 52 minutes, 16 seconds
        uptime = $1
        # 12 hours, 52 minutes, 16 seconds
        last_reload = $1
        uptime.should be_a(String)
        last_reload.should be_a(String)
      end
    end

    it "should successfully process asterisk command 'sip show peers'" do
      with_ami do |ami|
        actionid = Random::Secure.hex(8)
        response = ami.send_action({"action" => "Command", "command" => "sip show peers", "actionid" => actionid})
        response.actionid.should eq(actionid)
        response.output.as(Array(String)).join("\n").should match /test-account-905/im
      end
    end

    it "ami method 'command' should return expected result" do
      with_ami do |ami|
        # returns one line
        ami.command("core show version") =~ /Asterisk (\d{1,2}.\d{1,2}.\d{1,2}).+on a (\S+)/
        asterisk_version = $1
        asterisk_platform = $2
        asterisk_version.should be_a(String)
        asterisk_platform.should be_a(String)

        # returns array (two lines)
        ami.command("core show uptime").as(Array(String)).join("\n") =~ /(?|uptime: (.+)|reload: (.+))/i
        uptime = $1
        last_reload = $1
        uptime.should be_a(String)
        last_reload.should be_a(String)
      end
    end
  end
end
