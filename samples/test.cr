require "../src/asterisk.cr"

host = ENV.fetch("ASTERISK_MANAGER_HOST", "127.0.0.1")
port= ENV.fetch("ASTERISK_MANAGER_PORT", "55038")

ami = Asterisk::Manager.new(host, port)
ami.connect!

# puts ami.send_action({"action" => "ListCommands"})
# puts ami.send_action({"action" => "SIPpeers"})
puts ami.send_action({"action" => "Command", "command" => "agi show commands"})

ami.disconnect!
