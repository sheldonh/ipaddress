require 'spec_helper'

describe "IP" do
  describe ".parse" do
    it "returns an IP::V6 instance when given a string that contains at least one colon" do
      a = IP.parse("fc00::/7")
      a.should be_a(IP::V6)
    end

    it "returns an IP::V4 instance when given a string that contains no colons" do
      a = IP.parse("192.168.0.0/24")
      a.should be_a(IP::V4)
    end
  end
end
