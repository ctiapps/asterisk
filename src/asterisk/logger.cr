require "logger"

module Asterisk
  # time with milliseconds
  LOGGER = Logger.new STDERR,
    level: Logger::INFO,
    formatter: Logger::Formatter.new { |severity, datetime, progname, message, io|
      label = severity.unknown? ? "ANY" : severity.to_s
      io << label[0] << ", [" << datetime.to_utc.to_s("%Y-%m-%d %T.%L") << " #" << Process.pid << "] "
      io << label.rjust(5) << " -- " << progname << ": " << message
    }

  def self.logger
    LOGGER
  end
end
