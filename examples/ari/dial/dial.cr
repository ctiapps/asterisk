class Dial
  getter ari : Asterisk::ARI

  def initialize(@ari)
  end

  def start
    ari.start

    ari.on_stasis_start do |event|
      puts; puts; puts "(dial) on_stasis_start"
    end
  end

  def close
    ari.close
  end

  ##############################################################################
  @@app : Dial? = nil

  def self.start(ari = Asterisk::ARI.new url: %(http://#{ENV.fetch("ASTERISK_HOST", "127.0.0.1")}:#{ENV.fetch("ASTERISK_HTTP_PORT", "8088")}/ari),
                   app: ENV.fetch("ASTERISK_ARI_APPNAME", "asterisk.cr"),
                   username: ENV.fetch("ASTERISK_ARI_USERNAME", "asterisk.cr"),
                   password: ENV.fetch("ASTERISK_ARI_PASSWORD", "asterisk.cr"))
    @@app = Dial.new(ari)
    @@app.try &.start
  end

  def self.close
    @@app.try &.close
  end
end
