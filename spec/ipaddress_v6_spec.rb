require 'spec_helper'

describe "IPAddress::V6" do
  describe "#new" do
    it "takes a CIDR string" do
      a = IPAddress::V6.new("2001:470:1f09:553::1/64")
      a.address(:bits).should == 42540578174773399744588263950387249153
      a.mask(:size).should == 64
    end

    it "takes an unmasked address string and assumes a mask size of 128" do
      a = IPAddress::V6.new("::1")
      a.address(:bits).should == 1
      a.mask.should == 128
    end

    it "takes an integer address and mask size" do
      a = IPAddress::V6.new(1, 64)
      a.address.should == "::1"
      a.mask.should == 64
    end

    it "raises an ArgumentError if given no arguments" do
      expect { IPAddress::V6.new }.to raise_error(ArgumentError)
    end

    it "raises an ArgumentError if given more than 2 arguments" do
      expect { IPAddress::V4.new(1, 64, :wombat) }.to raise_error(ArgumentError)
    end
  end
end

