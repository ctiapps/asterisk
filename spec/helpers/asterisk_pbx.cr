# Give access to the Asterisk PBX through linux shell commands
module AsteriskPBX
  @@asterisk_full_path : String | Nil

  def self.asterisk
    @@asterisk_full_path ||= shell_cmd("sh", ["-c", "which asterisk"]).last.to_s.strip.chomp
  end

  # Does Asterisk PBX present within shell PATH?
  def self.present?
    ! asterisk.not_nil!.empty?
  end

  # start Asterisk PBX forked
  def self.start!
    shell_cmd asterisk, ["-vvvdddF"]
  end

  def self.stop
    shell_cmd(asterisk, ["-rx", "core stop now"])
  end

  def self.stop!
    stop
    shell_cmd "sh", ["-c", "ps x | grep asterisk | awk '{print $1}' | xargs kill -9"]
  end

  def self.running? : Bool
    code, result = shell_cmd(asterisk, ["-rx", "core show uptime"])
    code == 0 && (result =~ /Unable to connect/i).nil?
  end

  def self.asterisk_version : String
    code, result = shell_cmd("asterisk", ["-V"])
    result
  end

  def self.port_is_open?(port : String, host = "127.0.0.1") : Bool
    _, result = shell_cmd("sh", ["-c", "nmap -p #{port} #{host} | grep #{port} | awk '{print $2}'"])
    result.to_s.strip.chomp == "open"
  end

  private def self.shell_cmd(cmd, args)
    stdout_str = IO::Memory.new
    stderr_str = IO::Memory.new
    result = [] of Int32 | String

    status = Process.run(cmd, args: args, output: stdout_str, error: stderr_str)
    if status.success?
      result = [status.exit_code, "#{stdout_str}"]
    else
      result = [status.exit_code, "#{stderr_str}"]
    end

    stdout_str.close
    stderr_str.close

    result
  end
end
