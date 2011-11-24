require 'spec_helper'

describe "IP::V6" do
  describe "#new" do
    it "takes a CIDR string" do
      ip = IP::V6.new("fc00:1000:abcd:efff:0000:0000:0000:0001/64")
      ip.address(:bits).should == 0xfc00_1000_abcd_efff_0000_0000_0000_0001
      ip.mask(:size).should == 64
    end

    it "takes an unmasked address string and assumes a mask size of 128" do
      ip = IP::V6.new("0000:0000:0000:0000:0000:0000:0000:0001")
      ip.address(:bits).should == 1
      ip.mask.should == 128
    end

    it "takes an integer address and mask size" do
      ip = IP::V6.new(1, 64)
      ip.address(:bits).should == 1
      ip.mask.should == 64
    end

    it "accepts compressed leading zeroes" do
      ip = IP::V6.new("::1/128")
      ip.address(:bits).should == 0x0000_0000_0000_0000_0000_0000_0000_0001
    end

    it "accepts compressed inner zeroes" do
      ip = IP::V6.new("fc00:1000::1000:1/7")
      ip.address(:bits).should == 0xfc00_1000_0000_0000_0000_0000_1000_0001
    end

    it "accepts compressed trailing zeroes" do
      ip = IP::V6.new("fc00::/7")
      ip.address(:bits).should == 0xfc00_0000_0000_0000_0000_0000_0000_0000
    end

    it "accepts IPv4-mapped address notation" do
      ip = IP::V6.new("::ffff:192.168.0.1")
      ip.address(:bits).should == 0x0000_0000_0000_0000_0000_ffff_c0a8_0001
    end

    it "raises an ArgumentError if given no arguments" do
      expect { IP::V6.new }.to raise_error(ArgumentError)
    end

    it "raises an ArgumentError if given more than 2 arguments" do
      expect { IP::V6.new(1, 64, :wombat) }.to raise_error(ArgumentError)
    end
  end

  describe "#<=>" do
    it "returns -1 if the other IP::V6 has an higher integer address" do
      (IP::V6.new('::1') <=> IP::V6.new('::2')).should == -1
    end

    it "returns 1 if the other IP::V6 has a lower integer address" do
      (IP::V6.new('::2') <=> IP::V6.new('::1')).should == 1
    end

    it "returns 0 if the other IP::V6 has the same integer address" do
      (IP::V6.new('::1') <=> IP::V6.new('::1')).should == 0
    end
  end

  describe "#==" do
    it "is true if the other IP::V6 has the same address and mask size" do
      IP::V6.new('2001:470:1f09:553::1/64').should == IP::V6.new('2001:470:1f09:553:0:0:0:1/64')
    end

    it "is false if the other IP::V6 has a different address" do
      IP::V6.new('2001:470:1f09:553::1/64').should_not == IP::V6.new('2001:470:1f09:553::2/64')
    end

    it "is false if the other IP::V6 has a different mask size" do
      IP::V6.new('2001:470:1f09:553::1/64').should_not == IP::V6.new('2001:470:1f09:553::1/72')
    end
  end

  describe "#address" do
    it "returns the address in RFC5952 format if :string is given" do
      ip = IP::V6.new(0x2001_0470_1f09_0553_0000_0000_0000_0001, 64)
      ip.address(:string).should == "2001:470:1f09:553::1"
    end

    it "returns the address as a string in uncompressed format if :uncompressed is given" do
      ip = IP::V6.new(0x2001_0470_1f09_0553_0000_0000_0000_0001, 64)
      ip.address(:uncompressed).should == "2001:470:1f09:553:0:0:0:1"
    end

    it "returns the address as a string in unabbreviated format if :full is given" do
      ip = IP::V6.new(0x2001_0470_1f09_0553_0000_0000_0000_0001, 64)
      ip.address(:full).should == "2001:0470:1f09:0553:0000:0000:0000:0001"
    end

    it "returns the address as an integer bitstring if :bits is given" do
      ip  = IP::V6.new(0x2001_0470_1f09_0553_0000_0000_0000_0001, 64)
      ip.address(:bits).should == 0x2001_0470_1f09_0553_0000_0000_0000_0001
    end

    it "defaults to :string if no argument is given" do
      ip = IP::V6.new('::1')
      ip.address.should == ip.address(:string)
    end

    it "raises an ArgumentError if an unrecognized presentation is given" do
      expect { IP::V6.new('::1').address(:wombat) }.to raise_error(ArgumentError)
    end
  end

  describe "#adjacent?" do
    it "is true if the other IP::V6's network immediately follows this one" do
      this = IP::V6.new("2001:470:1f09:553::1/64")
      other = IP::V6.new("2001:470:1f09:554::1/64")
      this.adjacent?(other).should be_true
    end

    it "is true if the other IP::V6's network immediately precedes this one" do
      this = IP::V6.new("2001:470:1f09:553::1/64")
      other = IP::V6.new("2001:470:1f09:552::1/64")
      this.adjacent?(other).should be_true
    end

    it "is false if the other IP::V6's network includes this one" do
      this = IP::V6.new("2001:470:1f09:553::1/64")
      other = IP::V6.new("2001:470:1f09:552::1/61")
      this.adjacent?(other).should be_false
    end

    it "is false if the other IP::V6's network is included in this one" do
      this = IP::V6.new("2001:470:1f09:553::1/64")
      other = IP::V6.new("2001:470:1f09:553:4000::1/66")
      this.adjacent?(other).should be_false
    end

    it "is false for two host addresses with the same address" do
      this = IP::V6.new("2001:470:1f09:553::1")
      other = IP::V6.new("2001:470:1f09:553::1")
      this.adjacent?(other).should be_false
    end
  end

  describe "#broadcast" do
    it "returns the broadcast address as an IP::V6 if :instance is given" do
      ip = IP::V6.new("fc00::/7")
      ip.broadcast(:instance).should == IP::V6.new("fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/7")
    end

    it "returns the broadcast address as an integer bitstring if :bits is given" do
      ip = IP::V6.new("fc00::/7")
      ip.broadcast(:bits).should == 0xfdff_ffff_ffff_ffff_ffff_ffff_ffff_ffff
    end

    it "returns the broadcast address in RFC5952 format if :string is given" do
      ip = IP::V6.new("fc00::/64")
      ip.broadcast(:string).should == "fc00::ffff:ffff:ffff:ffff"
    end

    it "returns the broadcast address in uncompressed format if :uncompressed is given" do
      ip = IP::V6.new("fc00::/64")
      ip.broadcast(:uncompressed).should == "fc00:0:0:0:ffff:ffff:ffff:ffff"
    end

    it "returns the broadcast address in unabbreviated format if :full is given" do
      ip = IP::V6.new("fc00::/64")
      ip.broadcast(:full).should == "fc00:0000:0000:0000:ffff:ffff:ffff:ffff"
    end

    it "defaults to :instance if no presentation is given" do
      ip = IP::V6.new("fc00::/7")
      ip.broadcast.should == ip.broadcast(:instance)
    end

    it "returns itself if it is a broadcast address" do
      ip = IP::V6.new("fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/7")
      ip.broadcast.should equal(ip)
    end
  end

  describe "#each" do
    it "iterates over each address in the network, including network and broadcast address, if :address is given" do
      ip = IP::V6.new("fc00::/126")
      expected_addresses = [0, 1, 2, 3].collect { |i| IP::V6.new("fc00::#{i}/126") }
      addresses = []
      ip.each(:address) { |address| addresses << address }
      addresses.should == expected_addresses
    end

    it "iterates over each host address in the network, excluding network and broadcast address, if :host is given" do
      ip = IP::V6.new("fc00::/126")
      expected_addresses = [1, 2].collect { |i| IP::V6.new("fc00::#{i}/126") }
      addresses = []
      ip.each(:host) { |address| addresses << address }
      addresses.should == expected_addresses
    end

    it "defaults to :host if no argument is given" do
      ip = IP::V6.new("fc00::/126")
      expected_addresses = []
      ip.each(:host) { |address| expected_addresses << address }
      addresses = []
      ip.each { |address| addresses << address }
      addresses.should == expected_addresses
    end

    it "raises ArgumentError if an unknown argument is given" do
      ip = IP::V6.new("fc00::/126")
      expect { ip.each(:wombat) { |address| true } }.to raise_error(ArgumentError)
    end

    it "preserves its own mask in the instances yielded to the caller's block" do
      ip = IP::V6.new("fc00::/126")
      addresses = []
      ip.each { |address| addresses << address }
      addresses.collect(&:mask).should == [126, 126]
    end

    it "yields itself once if it is a /128" do
      ip = IP::V6.new("::1/128")
      addresses = []
      ip.each { |address| addresses << address }
      addresses.should have(1).element
      addresses[0].should equal(ip)
    end
  end

  describe "#follow?" do
    it "is true if the other IP::V6's network immediately precedes this one" do
      IP::V6.new("fc00::1:0/112").follow?(IP::V6.new("fc00::0:0/112")).should be_true
    end

    it "is false if the other IP::V6's network does not immediately precede this one" do
      IP::V6.new("fc00::2:0/112").follow?(IP::V6.new("fc00::0:0/112")).should be_false
    end
  end

  describe "#host?" do
    it "is true if the mask size is 128" do
      ip = IP::V6.new("::1/128")
      ip.host?.should be_true
    end

    it "is true if the mask size is 0" do
      ip = IP::V6.new("::/0")
      ip.host?.should be_true
    end

    it "is false if the address is the same as the masked address" do
      ip = IP::V6.new("fc00::/64")
      ip.host?.should be_false
    end

    it "is true if the address is the same as the masked address but the mask size is 32" do
      ip = IP::V6.new("fc00::/128")
      ip.host?.should be_true
    end

    it "is true if the address is the same as the masked address but the mask size is 0" do
      ip = IP::V6.new("fc00::/0")
      ip.host?.should be_true
    end
  end

  describe "#include?" do
    it "is true if the other IP::V6 is a host in this network" do
      network = IP::V6.new("fc00::/7")
      ip = IP::V6.new("fc00::1")
      network.include?(ip).should be_true
    end

    it "is false if the other IP::V6 is a host outside this network" do
      network = IP::V6.new("fc00::/7")
      ip = IP::V6.new("::1")
      network.include?(ip).should be_false
    end

    it "is true if the other IP::V6 is a network that fits inside this network" do
      network = IP::V6.new("fc00::/7")
      ip = IP::V6.new("fd00::/8")
      network.include?(ip).should be_true
    end

    it "is false if the other IP::V6 is a network that does not fit inside this network" do
      network = IP::V6.new("fc00::/7")
      ip = IP::V6.new("fe00::/8")
      network.include?(ip).should be_false
    end

    it "is true if the other IP::V6 is a host in this network but its network does not fit inside this network" do
      network = IP::V6.new("fc00::/8")
      ip = IP::V6.new("fc00::1/7")
      network.include?(ip).should be_true
    end

    it "is true if this is the unspecified (wildcard) address" do
      wildcard = IP::V6.new("::/0")
      ip = IP::V6.new("fc00::1/7")
      wildcard.include?(ip).should be_true
    end
  end

  describe "#ipv4_mapped?" do
    it "is true if the address starts with ::ffff and is a /96 or smaller" do
      ip = IP::V6.new("::ffff:192.168.0.1/104")
      ip.ipv4_mapped?.should be_true
    end

    it "is false if the address does not start with ::ffff" do
      ip = IP::V6.new("::192.168.0.1/104")
      ip.ipv4_mapped?.should be_false
    end

    it "is false if the address is larger than a /96" do
      ip = IP::V6.new("::ffff:192.168.0.1/64")
      ip.ipv4_mapped?.should be_false
    end
  end

  describe "#mask" do
    it "returns the mask size if :size is given" do
      ip = IP::V6.new("fc00::/64")
      ip.mask(:size).should == 64
    end

    it "returns the mask in RFC5952 format if :string is given" do
      ip = IP::V6.new("fc00::/64")
      ip.mask(:string).should == "ffff:ffff:ffff:ffff::"
    end

    it "returns the mask in uncompressed format if :uncompressed is given" do
      ip = IP::V6.new("fc00::/64")
      ip.mask(:uncompressed).should == "ffff:ffff:ffff:ffff:0:0:0:0"
    end

    it "returns the mask in unabbreviated format if :full is given" do
      ip = IP::V6.new("fc00::/64")
      ip.mask(:full).should == "ffff:ffff:ffff:ffff:0000:0000:0000:0000"
    end

    it "returns an integer bitmask if :bits is given" do
      ip = IP::V6.new("fc00::/64")
      ip.mask(:bits).should == 0xffff_ffff_ffff_ffff_0000_0000_0000_0000
    end

    it "defaults to :size if no argument is given" do
      ip = IP::V6.new("fc00::/64")
      ip.mask.should == ip.mask(:size)
    end

    it "raises an ArgumentError if an unrecognized presentation is given" do
      ip = IP::V6.new("fc00::/64")
      expect { ip.mask(:wombat) }.to raise_error(ArgumentError)
    end
  end

  describe "#network" do
    it "returns the network address as an IP::V6 if :instance is given" do
      ip = IP::V6.new("fc00::1/7")
      ip.network(:instance).should == IP::V6.new("fc00::/7")
    end

    it "returns the network address as an integer bitstring if :bits is given" do
      ip = IP::V6.new("fc00::1/7")
      ip.network(:bits).should == 0xfc00_0000_0000_0000_0000_0000_0000_0000
    end

    it "returns the network address in RFC5952 format if :string is given" do
      ip = IP::V6.new("fc00::1/7")
      ip.network(:string).should == "fc00::"
    end

    it "returns the network address in uncompressed format if :uncompressed is given" do
      ip = IP::V6.new("fc00::1/7")
      ip.network(:uncompressed).should == "fc00:0:0:0:0:0:0:0"
    end

    it "returns the network address in unabbreviated format if :full is given" do
      ip = IP::V6.new("fc00::1/7")
      ip.network(:full).should == "fc00:0000:0000:0000:0000:0000:0000:0000"
    end

    it "defaults to :instance if presentation is not given" do
      ip = IP::V6.new("fc00::1/7")
      ip.network.should == IP::V6.new("fc00::/7")
    end

    it "raises ArgumentError if an unknown presentation is given" do
      ip = IP::V6.new("fc00::1/7")
      expect { ip.network(:wombat) }.to raise_error(ArgumentError)
    end

    it "returns itself if it is a network address" do
      ip = IP::V6.new("fc00::/7")
      ip.network.should equal(ip)
    end
  end

  describe "#network?" do
    it "is false if the mask size is 128" do
      ip = IP::V6.new("fc00::1/128")
      ip.network?.should be_false
    end

    it "is false if the mask size is 0" do
      ip = IP::V6.new("::/0")
      ip.network?.should be_false
    end

    it "is true if the address is the same as the masked address" do
      ip = IP::V6.new("fc00::/7")
      ip.network?.should be_true
    end

    it "is false if the address is the same as the masked address but the mask size is 128" do
      ip = IP::V6.new("fc00::/128")
      ip.network?.should be_false
    end

    it "is false if the address is the same as the masked address but the mask size is 0" do
      ip = IP::V6.new("fc00::/0")
      ip.network?.should be_false
    end
  end

  describe "#precede?" do
    it "is true if the other IP::V6's network immediately follows this one" do
      IP::V6.new("fc00::/8").precede?(IP::V6.new("fd00::/8")).should be_true
    end

    it "is false if the other IP::V6's network does not immediately follow this one" do
      IP::V6.new("fc00::/8").precede?(IP::V6.new("fe00::/8")).should be_false
    end
  end

  describe "#to_s" do
    it "returns a CIDR string with the address in RFC5952 format" do
      ip = IP::V6.new("FC00::/7")
      ip.to_s.should == "fc00::/7"
    end

    it "compresses the longest run of zeroes" do
      ip = IP::V6.new(0xfc00_0000_0000_0001_0000_0000_0000_0001, 64)
      ip.to_s.should == "fc00:0:0:1::1/64"
    end

    it "compresses the first of the two or more longest runs of zeroes" do
      ip = IP::V6.new(0xfc00_0000_0000_0001_0000_0000_0001_0001, 64)
      ip.to_s.should == "fc00::1:0:0:1:1/64"
    end

    it "compresses leading zeroes" do
      ip = IP::V6.new(0x0000_0000_0000_0000_0000_feee_0000_0001, 96)
      ip.to_s.should == "::feee:0:1/96"
    end

    it "compresses trailing zeroes" do
      ip = IP::V6.new(0xfc00_0000_0000_0000_0000_0000_0000_0000, 7)
      ip.to_s.should == "fc00::/7"
    end

    it "compresses the longest run of leading or trailing zeroes" do
      ip = IP::V6.new(0x0000_0000_0001_0001_0001_0000_0000_0000, 86)
      ip.to_s.should == "0:0:1:1:1::/86"
    end

    it "compresses the leading zeroes if leading and trailing runs are the same length" do
      ip = IP::V6.new(0x0000_0000_0000_0001_0001_0000_0000_0000, 86)
      ip.to_s.should == "::1:1:0:0:0/86"
    end

    it "expresses the last 32 bits of an IPv4-mapped address as a dotted quad" do
      ip = IP::V6.new(0x0000_0000_0000_0000_0000_ffff_c0a8_0000, 96)
      ip.to_s.should == "::ffff:192.168.0.0/96"
    end
  end

end

