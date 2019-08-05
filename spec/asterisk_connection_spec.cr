require "./spec_helper"

# Testing Asterisk PBX functionality itself, assuming that crystal spec
# starting as a root or have enough permissions.
describe Asterisk::Server do
  it "should be installed on this server" do
    Asterisk::Server.installed?.should be_true
  end

  it "should start" do
    Asterisk::Server.kill
    sleep 1.second
    Asterisk::Server.start
    sleep 3.seconds
    Asterisk::Server.running?.should be_true
  end

  it "after start, Asterisk Manager should listen on 127.0.0.1:5038" do
    Asterisk::Server.port_is_open?("5038").should be_true
  end

  it "should stop by 'core stop now' CLI command" do
    Asterisk::Server.start
    sleep 3.seconds
    Asterisk::Server.stop
    sleep 3.seconds
    Asterisk::Server.running?.should be_false
  end

  it "should stop by kill -9 signal" do
    Asterisk::Server.start
    sleep 3.seconds
    Asterisk::Server.kill
    sleep 0.5.seconds
    Asterisk::Server.running?.should be_false
  end
end
