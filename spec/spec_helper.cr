require "spec"
require "uuid"
require "./helpers/*"
require "../src/asterisk/*"

STDOUT.sync = true
Spec.override_default_formatter(Spec::VerboseFormatter.new)

{% if flag?(:verbose) %}
  LOG_LEVEL = Logger::DEBUG
{% elsif flag?(:warn) %}
  LOG_LEVEL = Logger::WARN
{% else %}
  LOG_LEVEL = Logger::ERROR
{% end %}

def logger
  Asterisk.logger
end

logger.level = LOG_LEVEL

module TestHelpers
  def shell_command(command)
    io = IO::Memory.new
    Process.run(command, shell: true, output: io)
    io.to_s
  end

  def with_ami(host     = ENV.fetch("ASTERISK_HOST", "127.0.0.1"),
               port     = ENV.fetch("ASTERISK_AMI_PORT", "5038"),
               username = ENV.fetch("ASTERISK_AMI_USERNAME", "asterisk.cr"),
               secret   = ENV.fetch("ASTERISK_AMI_PASSWORD", "asterisk.cr"),
               &block )

    ami = Asterisk::AMI.new(host, port, username, secret)
    ami.login
    sleep 0.01

    yield ami

    ami.send_action({"action"  => "command", "command" => "hangup request all"})
    ami.logoff
    sleep 0.01
    logger.level = LOG_LEVEL
  end

  def with_agi
    unless Asterisk::Server.running?
      Asterisk::Server.start
      # let Asterisk boot
      sleep 3.seconds
    end

    agi = Asterisk::FastAGI.new # host: "127.0.0.1", port: 4573
    sleep 0.01
    yield agi
    agi.close
    sleep 0.01
    logger.level = LOG_LEVEL
  end

  def with_ari(url          = %(http://#{ENV.fetch("ASTERISK_HOST", "127.0.0.1")}:#{ENV.fetch("ASTERISK_HTTP_PORT", "8088")}/ari),
               app          = ENV.fetch("ASTERISK_ARI_APPNAME", "asterisk.cr"),
               username     = ENV.fetch("ASTERISK_ARI_USERNAME", "asterisk.cr"),
               password     = ENV.fetch("ASTERISK_ARI_PASSWORD", "asterisk.cr"),
               ami_host     = ENV.fetch("ASTERISK_HOST", "127.0.0.1"),
               ami_port     = ENV.fetch("ASTERISK_AMI_PORT", "5038"),
               ami_username = ENV.fetch("ASTERISK_AMI_USERNAME", "asterisk.cr"),
               ami_secret   = ENV.fetch("ASTERISK_AMI_PASSWORD", "asterisk.cr"),
               &block)

    with_ami host: ami_host, port: ami_port, username: ami_username, secret: ami_secret do |ami|
      ari = Asterisk::ARI.new(url, app, username, password)

      ari.start
      sleep 0.01

      yield ami, ari

      ari.close
      sleep 0.01
    end
  end

  # Getter of SIP UDP Bindaddress for connected asterisk instance.
  # We use it to generate loopback SIP calls:
  # https://gist.github.com/andrius/bce51f8be4323a9dda234ebe2d51befc
  macro get_bindaddress
    response = ami.send_action({"action"  => "Command",
                                "command" => "sip show settings"},
                                expects_answer_before: 2.0)

    # logger.debug "SIP show settings:\n#{response.pretty_inspect}\n---"

    response = [ response["output"]? ||
                  response["unknown"]? ||
                  ["No data"]
                ].flatten.join("\n").strip.chomp.strip

    bindaddress = if /(?:UDP Bindaddress:\s+)([0-9.]+:\d{1,5})/im =~ response
                    $1
                  else
                    "127.0.0.1"
                  end

    # logger.debug "UDP bind_address of Asterisk (where to send test calls): #{bindaddress}"

    bindaddress
  end

  macro generate_call(**data)
    ami_action = { "action"      => "originate",
                   "channel"     => {{ data[:channel]     || "Local/ari@asterisk.cr" }}.to_s,
                   "application" => {{ data[:application] || "Wait" }}.to_s,
                   "data"        => {{ data[:app_data]    || "1" }}.to_s,
                   "async"       => {{ data[:async]       || true }}.to_s,
                   "earlymedia"  => "true",
                   "timeout"     => {{ data[:timeout]     || 30_000 }}.to_s
                 }
    # logger.debug "Sending AMI action\n#{ami_action.pretty_inspect}\n---"
    response = ami.send_action(ami_action)
    response.message.should match /Originate successfully queued/i
  end
end

extend TestHelpers
