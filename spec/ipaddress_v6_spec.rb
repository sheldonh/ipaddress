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
      a.address.should == "0:0:0:0:0:0:0:1"
      a.mask.should == 64
    end

    it "raises an ArgumentError if given no arguments" do
      expect { IPAddress::V6.new }.to raise_error(ArgumentError)
    end

    it "raises an ArgumentError if given more than 2 arguments" do
      expect { IPAddress::V4.new(1, 64, :wombat) }.to raise_error(ArgumentError)
    end
  end

  describe "#<=>" do
    it "returns -1 if the other IPAddress::V6 has an higher integer address" do
      (IPAddress::V6.new('::1') <=> IPAddress::V6.new('::2')).should == -1
    end

    it "returns 1 if the other IPAddress::V6 has a lower integer address" do
      (IPAddress::V6.new('::2') <=> IPAddress::V6.new('::1')).should == 1
    end

    it "returns 0 if the other IPAddress::V6 has the same integer address" do
      (IPAddress::V6.new('::1') <=> IPAddress::V6.new('::1')).should == 0
    end
  end

  describe "#==" do
    it "is true if the other IPAddress::V6 has the same address and mask size" do
      IPAddress::V6.new('2001:470:1f09:553::1/64').should == IPAddress::V6.new('2001:470:1f09:553:0:0:0:1/64')
    end

    it "is false if the other IPAddress::V6 has a different address" do
      IPAddress::V6.new('2001:470:1f09:553::1/64').should_not == IPAddress::V6.new('2001:470:1f09:553::2/64')
    end

    it "is false if the other IPAddress::V6 has a different mask size" do
      IPAddress::V6.new('2001:470:1f09:553::1/64').should_not == IPAddress::V6.new('2001:470:1f09:553::1/72')
    end
  end

  describe "#address" do
    it "returns the address as a string in uncompressed format if :string is given" do
      a = IPAddress::V6.new(42540578174773399744588263950387249153, 64)
      a.address(:string).should == "2001:470:1f09:553:0:0:0:1"
    end

    it "returns the address as a string in compressed format if :compressed is given" do
      a = IPAddress::V6.new(42540578174773399744588263950387249153, 64)
      a.address(:compressed).should == "2001:470:1f09:553::1"
    end

    it "returns the address as an integer bitstring if :bits is given" do
      a  = IPAddress::V6.new(42540578174773399744588263950387249153, 64)
      a.address(:bits).should == 42540578174773399744588263950387249153
    end

    it "defaults to :string if no argument is given" do
      a = IPAddress::V6.new('::1')
      a.address.should == a.address(:string)
    end

    it "raises an ArgumentError if an unrecognized presentation is given" do
      expect { IPAddress::V6.new('::1').address(:wombat) }.to raise_error(ArgumentError)
    end
  end

  describe "#adjacent?" do
    it "is true if the other IPAddress::V6's network immediately follows this one" do
      this = IPAddress::V6.new("2001:470:1f09:553::1/64")
      other = IPAddress::V6.new("2001:470:1f09:554::1/64")
      this.adjacent?(other).should be_true
    end

    it "is true if the other IPAddress::V6's network immediately precedes this one" do
      this = IPAddress::V6.new("2001:470:1f09:553::1/64")
      other = IPAddress::V6.new("2001:470:1f09:552::1/64")
      this.adjacent?(other).should be_true
    end

    it "is false if the other IPAddress::V6's network includes this one" do
      this = IPAddress::V6.new("2001:470:1f09:553::1/64")
      other = IPAddress::V6.new("2001:470:1f09:552::1/61")
      this.adjacent?(other).should be_false
    end

    it "is false if the other IPAddress::V6's network is included in this one" do
      this = IPAddress::V6.new("2001:470:1f09:553::1/64")
      other = IPAddress::V6.new("2001:470:1f09:553:4000::1/66")
      this.adjacent?(other).should be_false
    end

    it "is false for two host addresses with the same address" do
      this = IPAddress::V6.new("2001:470:1f09:553::1")
      other = IPAddress::V6.new("2001:470:1f09:553::1")
      this.adjacent?(other).should be_false
    end
  end

end

