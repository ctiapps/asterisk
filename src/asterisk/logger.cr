require "logger"

module Asterisk
  LOGGER = Logger.new(STDOUT)
  LOGGER.level = Logger::DEBUG

  def self.logger
    LOGGER
  end
end

