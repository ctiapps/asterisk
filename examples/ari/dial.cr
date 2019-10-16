require "../../src/asterisk"
require "./dial/*"

ari = Asterisk::ARI.new url:      %(http://#{ENV.fetch("ASTERISK_HOST", "127.0.0.1")}:#{ENV.fetch("ASTERISK_HTTP_PORT", "8088")}/ari),
                        app:      ENV.fetch("ASTERISK_ARI_APPNAME", "asterisk.cr"),
                        username: ENV.fetch("ASTERISK_ARI_USERNAME", "asterisk.cr"),
                        password: ENV.fetch("ASTERISK_ARI_PASSWORD", "asterisk.cr")

Dial.start(ari)
