require "./spec_helper"

describe Asterisk::AMI do
  # Testing basic actions
  describe "#on_hooks" do
    it "should trigger 'FullyBooted' callback" do
      # can't use with_ami wrapper: FullyBooted aproaching next after login
      ami = Asterisk::AMI.new username: "asterisk.cr", secret: "asterisk.cr"

      ami.on_event("FullyBooted") do |ami, event|
        event.event.should eq("FullyBooted")
        event["status"].should match /Fully Booted/i
        # runner already processed "FullyBooted" and ami.connected? expected to
        # be true
        # pp ami
        # ami.connected?.should be_true
      end

      ami.login
      # callback will be triggered by AMI right after login action
      sleep 0.2
      ami.logoff
    end

    it "should trigger 'on_close' callback" do
      with_ami do |ami|
        ami.on_close do |ami|
          # AMI connection should be closed already
          ami.connected?.should be_false
        end
      end
    end

  end
end
