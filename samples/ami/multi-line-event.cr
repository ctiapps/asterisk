require "../../src/asterisk.cr"

host = ENV.fetch("ASTERISK_MANAGER_HOST", "127.0.0.1")
port= ENV.fetch("ASTERISK_MANAGER_PORT", "5038")

ami = Asterisk::AMI.new(host, port)
ami.connect!

# puts ami.send_action({"action" => "ListCommands"})
# puts ami.send_action({"action" => "SIPpeers"})
puts ami.send_action({"action" => "Command", "command" => "agi show commands"})

puts "--------- RESTART ASTERISK TO CHECK OF RECONNECT WORKS (YOU HAVE 15 SECONDS)"
sleep 15
puts ami.send_action({"action" => "SIPpeers"})

ami.disconnect!
