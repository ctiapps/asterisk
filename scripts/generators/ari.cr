require "uri"
require "http/client"
require "json"
require "./ari/*"

module Asterisk
  module Generator
    class ARI
      def initialize
        # base_url = ENV.fetch("ARI_URL", "http://svn.asterisk.org/svn/asterisk/trunk/rest-api/api-docs")
        base_url = ENV.fetch("ARI_URL", "http://127.0.0.1:8088/ari/api-docs")
        base_url = "#{base_url}/%{resource_name}.json"
        username = ENV["ARI_USERNAME"]? || "asterisk.cr"
        password = ENV["ARI_PASSWORD"]? || "asterisk.cr"

        resources = [] of String
        url = base_url % {resource_name: "resources"}
        url = URI.parse(url)
        if username && password
          url.user = username
          url.password = password
        end
        response = HTTP::Client.get(url)
        resource = JSON.parse(response.body)
        resource["apis"].as_a.each do |resource|
          if resource["path"].to_s =~ /^\/\S+\/(\w+)\..+/
            resources.push $1
          end
        end

        # ["asterisk",
        #  "endpoints",
        #  "channels",
        #  "bridges",
        #  "recordings",
        #  "sounds",
        #  "playbacks",
        #  "deviceStates",
        #  "mailboxes",
        #  "events",
        #  "applications"]
        # TEST with only one resource
        resources.delete "asterisk"
        # resources = %w{events}
        # resources = %w{channels}

        resources.each do |resource_name|
          url = base_url % {resource_name: resource_name}
          puts ">> generating #{resource_name} from #{url.inspect}"
          url = URI.parse(url)
          if username && password
            url.user = username
            url.password = password
          end

          response = HTTP::Client.get(url)
          api_data = JSON.parse(response.body)
          Resource.new api_data
          Models.new api_data
          Events.new api_data
        end
      end
    end
  end
end
