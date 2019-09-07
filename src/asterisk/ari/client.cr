require "uri"
require "http/params"
require "http/client"
require "http/web_socket"
require "./*"
require "./resources/*"
require "./models/*"
require "./events/*"

module Asterisk
  class ARI
    class Client
      include Callbacks
    end
  end
end
