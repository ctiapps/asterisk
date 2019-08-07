require "socket"
require "./agi"

module Asterisk
  class FastAGI < AGI
    @server = TCPServer.new
    @running = false
    getter logger : Logger = Asterisk.logger

    class LoginError < Exception
    end

    class ConnectionError < Exception
    end

    def initialize(@host = "127.0.0.1", @port : String | Int32 = 4573, @logger : Logger = Asterisk.logger)
    end

    # on_close callback
    def on_close(&@on_close : AMI ->)
    end

    def start(&@block : AGI ->)
      @server = TCPServer.new(@host, @port.to_i)
      @running = true
      logger.info "#{self.class} FastAGI service listen on #{@host}:#{@port}"
      spawn do
        loop do
          logger.info "Spawning another process"
          process(@server.accept)
        rescue IO::Error
          puts "error @running: #{@running.to_s}"
          break
        end
      end
    end

    def close
      @running = false
      @server.close
      logger.info "server closed"
    end

    def process(client : TCPSocket)
      spawn do
        client_addr = client.remote_address
        logger.info "#{client_addr} connected"
        @block.try &.call(AGI.new(client, client))
        client.close
      rescue IO::EOFError
        logger.info "#{client_addr} disconnected"
      ensure
      end
    end

  end
end
