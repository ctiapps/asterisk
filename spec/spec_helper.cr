require "spec"
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
