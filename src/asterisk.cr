module Asterisk
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}
end

require "./asterisk/*"
