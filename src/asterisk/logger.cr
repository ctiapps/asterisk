require "logger"

module Asterisk
  LOGGER = Logger.new(STDERR)
  LOGGER.level = Logger::DEBUG

  def self.logger
    LOGGER
  end
end

