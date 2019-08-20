require "uri"
require "http/client"
require "json"

# base_url = ENV.fetch("ARI_URL", "http://svn.asterisk.org/svn/asterisk/trunk/rest-api/api-docs")
base_url = ENV.fetch("ARI_URL", "http://127.0.0.1:8088/ari/api-docs")
base_url = "#{base_url}/%{resource_name}.json"
username = ENV["ARI_USERNAME"]? || "asterisk.cr"
password = ENV["ARI_PASSWORD"]? || "asterisk.cr"
resources = %w{ applications
                asterisk
                bridges
                channels
                deviceStates
                endpoints
                events
                mailboxes
                playbacks
                recordings
                sounds
              }

resources.each do |resource_name|
  url = base_url % { resource_name: resource_name }
  puts ">> generating #{resource_name} from #{url.inspect}"
  url = URI.parse(url)
  if username && password
    url.user = username
    url.password = password
  end

  response =HTTP::Client.get(url)

  pp JSON.parse(response.body) if resource_name == "bridges"
end
