require 'spec_helper'

describe "IPAddress" do
  describe ".parse" do
    it "returns an IPAddress::V6 instance when given a string that contains at least one colon" do
      a = IPAddress.parse("fc00::/7")
      a.should be_a(IPAddress::V6)
    end

    it "returns an IPAddress::V4 instance when given a string that contains no colons" do
      a = IPAddress.parse("192.168.0.0/24")
      a.should be_a(IPAddress::V4)
    end
  end
end
