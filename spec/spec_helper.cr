require "spec"
require "uuid"
require "./helpers/*"
require "../src/asterisk"

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
  def with_ami(username = "asterisk.cr", secret = "asterisk.cr", &block)
    unless Asterisk::Server.running?
      Asterisk::Server.start
      # let Asterisk boot
      sleep 3.seconds
    end

    ami = Asterisk::AMI.new username: username, secret: secret
    ami.login

    yield ami

    ami.logoff
  end
end

extend TestHelpers
