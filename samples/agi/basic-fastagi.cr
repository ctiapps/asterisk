require "../../src/asterisk.cr"

agi = Asterisk::FastAGI.new
agi.start

loop do
  puts "in loop"
  sleep 5
end

# agi.logger.debug ARGV

# agi.command "VERBOSE \"this is a test\" 3"
# agi.command "THIS_IS_ALL_WRONG"
# agi.command  "HANGUP"
# sleep 5
# agi.command "EXEC \"DIAL SIP/k@andrius.mobi\""


