require "../../src/asterisk.cr"

host = ENV.fetch("ASTERISK_MANAGER_HOST", "127.0.0.1")
port= ENV.fetch("ASTERISK_MANAGER_PORT", "55038")

ami = Asterisk::AMI.new(host, port)
ami.connect!

# while in speep mode, AMI events still coming to the listener
(1..10).each do |counter|
  puts "[#{counter}] in sleep mode"
  sleep 1
end

ami.disconnect!
