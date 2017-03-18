require "../src/asterisk.cr"

ami = Asterisk::Manager.new
ami.connect
puts ami.send_action({"action" => "ListCommands"})
puts ami.send_action({"action" => "SIPpeers"})
sleep 3
ami.disconnect
sleep 10
