require "./generators/*"

puts "#{Asterisk::Generator.current_dir}/src/asterisk/agi/commands.cr"

Asterisk::Generator::ARI.new
