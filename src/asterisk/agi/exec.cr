module Asterisk
  class AGI
    def exec(asterisk_command, options)
      command "EXEC #{asterisk_command} #{options}".strip
    end
  end
end
