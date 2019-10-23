require "../../spec_helper"
require "../../../examples/ari/dial/*"

describe Dial do
  it "should receive call" do
    with_ari do |ami, ari|
      # let's reuse ARI instance, so we can track events
      Dial.start(ari)

      ari.on_stasis_start do
        logger.info "(test) on_stasis_start"
      end

      sleep 0.01

      generate_call

      Dial.close
      sleep 1
    end
  end
end
