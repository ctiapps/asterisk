require "../../src/asterisk.cr"

agi = Asterisk::AGI.new

agi.logger.debug ARGV

agi.command "VERBOSE \"this is a test\" 3"
agi.command "THIS_IS_ALL_WRONG"
#agi.command  "HANGUP"
sleep 5
agi.exec "Dial", "SIP/k@andrius.mobi"


