require "socket"
require "./agi"

module Asterisk
  class FastAGI
    @server : TCPServer

    class LoginError < Exception
    end

    class ConnectionLostError < Exception
    end

    def logger
      Asterisk.logger
    end

    def initialize
      @server = TCPServer.new "127.0.0.1", 9000
    end

    def start
      logger.info "listen on 127.0.0.1:9000. Don't forget to loop for process"
      spawn process(@server.accept)
      spawn process(@server.accept)
      spawn process(@server.accept)
    end

    def stop
      @server.close
    end

    def process(client : TCPSocket)
      client_addr = client.remote_address
      logger.info "#{client_addr} connected"
      AGI.new(client, client)
    rescue IO::EOFError
      logger.info "#{client_addr} disconnected"
    ensure
      client.close
    end

  end
end
