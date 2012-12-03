require 'spec_helper'

# This script is tested through manual acceptance tests.
# This file mostly provides a starting point if proper
# tests were to be added in the future.

module Streamio::CLI
  describe App do
    it "should work" do
      expect { subject.export }.to raise_error(SystemExit)
    end
  end
end
