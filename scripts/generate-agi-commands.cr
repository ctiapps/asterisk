require "./generators/*"

agi_commands = Asterisk::Generator::AGICommand.new

file = File.open "#{Asterisk::Generator.current_dir}/src/asterisk/agi/commands.cr", "w"
file.puts agi_commands.generate!
file.close
