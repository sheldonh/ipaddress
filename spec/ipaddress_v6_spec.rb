require 'spec_helper'

describe "IPAddress::V6" do
  describe "#new" do
    it "takes a CIDR string" do
      a = IPAddress::V6.new("fc00:1000:abcd:efff:0000:0000:0000:0001/64")
      a.address(:bits).should == 0xfc00_1000_abcd_efff_0000_0000_0000_0001
      a.mask(:size).should == 64
    end

    it "takes an unmasked address string and assumes a mask size of 128" do
      a = IPAddress::V6.new("0000:0000:0000:0000:0000:0000:0000:0001")
      a.address(:bits).should == 1
      a.mask.should == 128
    end

    it "takes an integer address and mask size" do
      a = IPAddress::V6.new(1, 64)
      a.address(:bits).should == 1
      a.mask.should == 64
    end

    it "accepts compressed leading zeroes" do
      a = IPAddress::V6.new("::1/128")
      a.address(:bits).should == 0x0000_0000_0000_0000_0000_0000_0000_0001
    end

    it "accepts compressed inner zeroes" do
      a = IPAddress::V6.new("fc00:1000::1000:1/7")
      a.address(:bits).should == 0xfc00_1000_0000_0000_0000_0000_1000_0001
    end

    it "accepts compressed trailing zeroes" do
      a = IPAddress::V6.new("fc00::/7")
      a.address(:bits).should == 0xfc00_0000_0000_0000_0000_0000_0000_0000
    end

    it "raises an ArgumentError if given no arguments" do
      expect { IPAddress::V6.new }.to raise_error(ArgumentError)
    end

    it "raises an ArgumentError if given more than 2 arguments" do
      expect { IPAddress::V6.new(1, 64, :wombat) }.to raise_error(ArgumentError)
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
      a = IPAddress::V6.new(0x2001_0470_1f09_0553_0000_0000_0000_0001, 64)
      a.address(:string).should == "2001:470:1f09:553:0:0:0:1"
    end

    it "returns the address as a string in compressed format if :compressed is given" do
      a = IPAddress::V6.new(0x2001_0470_1f09_0553_0000_0000_0000_0001, 64)
      a.address(:compressed).should == "2001:470:1f09:553::1"
    end

    it "returns the address as an integer bitstring if :bits is given" do
      a  = IPAddress::V6.new(0x2001_0470_1f09_0553_0000_0000_0000_0001, 64)
      a.address(:bits).should == 0x2001_0470_1f09_0553_0000_0000_0000_0001
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

  describe "#broadcast" do
    it "returns the broadcast address as an IPAddress::V6 if :instance is given" do
      a = IPAddress::V6.new("fc00::/7")
      a.broadcast(:instance).should == IPAddress::V6.new("fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/7")
    end

    it "returns the broadcast address as an integer bitstring if :bits is given" do
      a = IPAddress::V6.new("fc00::/7")
      a.broadcast(:bits).should == 0xfdff_ffff_ffff_ffff_ffff_ffff_ffff_ffff
    end

    it "returns the broadcast address as a colon-separated hexen string if :string is given" do
      a = IPAddress::V6.new("fc00::/7")
      a.broadcast(:string).should == "fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"
    end

    it "defaults to :instance if no presentation is given" do
      a = IPAddress::V6.new("fc00::/7")
      a.broadcast.should == a.broadcast(:instance)
    end

    it "returns itself if it is a broadcast address" do
      a = IPAddress::V6.new("fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/7")
      a.broadcast.should equal(a)
    end
  end

  describe "#each" do
    it "iterates over each address in the network, including network and broadcast address, if :address is given" do
      a = IPAddress::V6.new("fc00::/126")
      expected_addresses = [0, 1, 2, 3].collect { |i| IPAddress::V6.new("fc00::#{i}/126") }
      addresses = []
      a.each(:address) { |address| addresses << address }
      addresses.should == expected_addresses
    end

    it "iterates over each host address in the network, excluding network and broadcast address, if :host is given" do
      a = IPAddress::V6.new("fc00::/126")
      expected_addresses = [1, 2].collect { |i| IPAddress::V6.new("fc00::#{i}/126") }
      addresses = []
      a.each(:host) { |address| addresses << address }
      addresses.should == expected_addresses
    end

    it "defaults to :host if no argument is given" do
      a = IPAddress::V6.new("fc00::/126")
      expected_addresses = []
      a.each(:host) { |address| expected_addresses << address }
      addresses = []
      a.each { |address| addresses << address }
      addresses.should == expected_addresses
    end

    it "raises ArgumentError if an unknown argument is given" do
      a = IPAddress::V6.new("fc00::/126")
      expect { a.each(:wombat) { |address| true } }.to raise_error(ArgumentError)
    end

    it "preserves its own mask in the instances yielded to the caller's block" do
      a = IPAddress::V6.new("fc00::/126")
      addresses = []
      a.each { |address| addresses << address }
      addresses.collect(&:mask).should == [126, 126]
    end

    it "yields itself once if it is a /128" do
      a = IPAddress::V6.new("::1/128")
      addresses = []
      a.each { |address| addresses << address }
      addresses.should have(1).element
      addresses[0].should equal(a)
    end
  end

  describe "#follow?" do
    it "is true if the other IPAddress::V6's network immediately precedes this one" do
      IPAddress::V6.new("fc00::1:0/112").follow?(IPAddress::V6.new("fc00::0:0/112")).should be_true
    end

    it "is false if the other IPAddress::V6's network does not immediately precede this one" do
      IPAddress::V6.new("fc00::2:0/112").follow?(IPAddress::V6.new("fc00::0:0/112")).should be_false
    end
  end

  describe "#host?" do
    it "is true if the mask size is 128" do
      a = IPAddress::V6.new("::1/128")
      a.host?.should be_true
    end

    it "is true if the mask size is 0" do
      a = IPAddress::V6.new("::/0")
      a.host?.should be_true
    end

    it "is false if the address is the same as the masked address" do
      a = IPAddress::V6.new("fc00::/64")
      a.host?.should be_false
    end

    it "is true if the address is the same as the masked address but the mask size is 32" do
      a = IPAddress::V6.new("fc00::/128")
      a.host?.should be_true
    end

    it "is true if the address is the same as the masked address but the mask size is 0" do
      a = IPAddress::V6.new("fc00::/0")
      a.host?.should be_true
    end
  end

  describe "#include?" do
    it "is true if the other IPAddress::V6 is a host in this network" do
      network = IPAddress::V6.new("fc00::/7")
      a = IPAddress::V6.new("fc00::1")
      network.include?(a).should be_true
    end

    it "is false if the other IPAddress::V6 is a host outside this network" do
      network = IPAddress::V6.new("fc00::/7")
      a = IPAddress::V6.new("::1")
      network.include?(a).should be_false
    end

    it "is true if the other IPAddress::V6 is a network that fits inside this network" do
      network = IPAddress::V6.new("fc00::/7")
      a = IPAddress::V6.new("fd00::/8")
      network.include?(a).should be_true
    end

    it "is false if the other IPAddress::V6 is a network that does not fit inside this network" do
      network = IPAddress::V6.new("fc00::/7")
      a = IPAddress::V6.new("fe00::/8")
      network.include?(a).should be_false
    end

    it "is true if the other IPAddress::V6 is a host in this network but its network does not fit inside this network" do
      network = IPAddress::V6.new("fc00::/8")
      a = IPAddress::V6.new("fc00::1/7")
      network.include?(a).should be_true
    end

    it "is true if this is the unspecified (wildcard) address" do
      wildcard = IPAddress::V6.new("::/0")
      a = IPAddress::V6.new("fc00::1/7")
      wildcard.include?(a).should be_true
    end
  end

  describe "#mask" do
    it "returns the mask size if :size is given" do
      a = IPAddress::V6.new("fc00::/64")
      a.mask(:size).should == 64
    end

    it "returns a colon-separated hexen string if :string is given" do
      a = IPAddress::V6.new("fc00::/64")
      a.mask(:string).should == "ffff:ffff:ffff:ffff:0:0:0:0"
    end

    it "returns an integer bitmask if :bits is given" do
      a = IPAddress::V6.new("fc00::/64")
      a.mask(:bits).should == 0xffff_ffff_ffff_ffff_0000_0000_0000_0000
    end

    it "defaults to :size if no argument is given" do
      a = IPAddress::V6.new("fc00::/64")
      a.mask.should == a.mask(:size)
    end

    it "raises an ArgumentError if an unrecognized presentation is given" do
      a = IPAddress::V6.new("fc00::/64")
      expect { a.mask(:wombat) }.to raise_error(ArgumentError)
    end
  end

  describe "#network" do
    it "returns the network address as an IPAddress::V6 if :instance is given" do
      a = IPAddress::V6.new("fc00::1/7")
      a.network(:instance).should == IPAddress::V6.new("fc00::/7")
    end

    it "returns the network address as an integer bitstring if :bits is given" do
      a = IPAddress::V6.new("fc00::1/7")
      a.network(:bits).should == 0xfc00_0000_0000_0000_0000_0000_0000_0000
    end

    it "returns the network address as a colon-separated hexen string if :string is given" do
      a = IPAddress::V6.new("fc00::1/7")
      a.network(:string).should == "fc00:0:0:0:0:0:0:0"
    end

    it "defaults to :instance if presentation is not given" do
      a = IPAddress::V6.new("fc00::1/7")
      a.network.should == IPAddress::V6.new("fc00::/7")
    end

    it "raises ArgumentError if an unknown presentation is given" do
      a = IPAddress::V6.new("fc00::1/7")
      expect { a.network(:wombat) }.to raise_error(ArgumentError)
    end

    it "returns itself if it is a network address" do
      a = IPAddress::V6.new("fc00::/7")
      a.network.should equal(a)
    end
  end

  describe "#network?" do
    it "is false if the mask size is 128" do
      a = IPAddress::V6.new("fc00::1/128")
      a.network?.should be_false
    end

    it "is false if the mask size is 0" do
      a = IPAddress::V6.new("::/0")
      a.network?.should be_false
    end

    it "is true if the address is the same as the masked address" do
      a = IPAddress::V6.new("fc00::/7")
      a.network?.should be_true
    end

    it "is false if the address is the same as the masked address but the mask size is 128" do
      a = IPAddress::V6.new("fc00::/128")
      a.network?.should be_false
    end

    it "is false if the address is the same as the masked address but the mask size is 0" do
      a = IPAddress::V6.new("fc00::/0")
      a.network?.should be_false
    end
  end

  describe "#precede?" do
    it "is true if the other IPAddress::V6's network immediately follows this one" do
      IPAddress::V6.new("fc00::/8").precede?(IPAddress::V6.new("fd00::/8")).should be_true
    end

    it "is false if the other IPAddress::V6's network does not immediately follow this one" do
      IPAddress::V6.new("fc00::/8").precede?(IPAddress::V6.new("fe00::/8")).should be_false
    end
  end

end

