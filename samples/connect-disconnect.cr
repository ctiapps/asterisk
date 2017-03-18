require "../src/asterisk.cr"

ami = Asterisk::Manager.new
ami.connect

# while in speep mode, AMI events still coming to the listener
(1..10).each do |counter|
  puts "[#{counter}] in sleep mode"
  sleep 1
end

ami.disconnect
