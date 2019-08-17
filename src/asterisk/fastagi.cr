require "./logger.cr"
require "./agi"
require "socket"

module Asterisk
  class FastAGI < AGI
    @fastagi = TCPServer.new
    @running = false

    def initialize(@host = "127.0.0.1", @port : String | Int32 = 4573, @logger : Logger = Asterisk.logger)
    end

    # on_close callback
    def on_close(&@on_close : AGI ->)
    end

    def start(&@block : AGI ->)
      @fastagi = TCPServer.new(@host, @port.to_i)
      @running = true
      logger.info "#{self.class}: service listen on #{@host}:#{@port}"
      spawn do
        loop do
          logger.info "#{self.class}: spawning another process"
          process(@fastagi.accept)
        rescue IO::Error
          close
          break
        end
      end
    end

    def close
      @running = false
      unless @fastagi.closed?
        @fastagi.close
        logger.info "#{self.class}: server closed"
      end
    end

    def process(client : TCPSocket)
      spawn do
        client_addr = client.remote_address
        logger.info "#{self.class}: #{client_addr} connected"
        @block.try &.call(AGI.new(client, client))
        client.close
      rescue IO::EOFError
        logger.info "#{self.class}: #{client_addr} disconnected"
      end
    end

    def running?
      @running
    end

    def closed?
      !running? && @fastagi.closed?
    end
  end
end
