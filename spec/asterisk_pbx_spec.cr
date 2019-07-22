require "./spec_helper"

# Testing Asterisk PBX functionality itself, assuming that crystal spec
# starting as a root or have enough permissions.
describe AsteriskPBX do
  it "should be installed on this server" do
    AsteriskPBX.present?.should be_true
  end

  it "should start" do
    AsteriskPBX.stop!
    sleep 1.second
    AsteriskPBX.start!
    sleep 5.seconds
    AsteriskPBX.running?.should be_true
  end

  it "after start, Asterisk Manager should listen on 127.0.0.1:5038" do
    AsteriskPBX.port_is_open?("5038").should be_true
  end

  it "should stop by 'core stop now' CLI command" do
    AsteriskPBX.stop
    sleep 5.seconds
    AsteriskPBX.running?.should be_false
  end
end
