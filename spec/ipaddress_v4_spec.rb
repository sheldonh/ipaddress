require 'spec_helper'

describe "IPAddress::V4" do
  describe "#new" do
    it "takes a CIDR string" do
      expect { IPAddress::V4.new("192.168.0.0/24") }.to_not raise_error
    end

    it "takes an address/mask dotted quad string" do
      ip = IPAddress::V4.new("192.168.0.0/255.255.255.0")
      ip.mask.should == IPAddress::V4.new("192.168.0.0/24").mask
    end

    it "takes an unmasked address string and assumes a mask size of 32" do
      ip = IPAddress::V4.new("192.168.0.1")
      ip.mask.should == 32
    end

    it "takes an integer address and mask size" do
      ip = IPAddress::V4.new(3232235520, 24)
      ip.address.should == "192.168.0.0"
      ip.mask.should == 24
    end

    it "raises an ArgumentError if given no arguments" do
      expect { IPAddress::V4.new }.to raise_error(ArgumentError)
    end

    it "raises an ArgumentError if given more than 2 arguments" do
      expect { IPAddress::V4.new(3232235520, 24, :wombat) }.to raise_error(ArgumentError)
    end
  end

  describe "#<=>" do
    it "returns -1 if the other IPAddress::V4 has an higher integer address" do
      this = IPAddress::V4.new("192.168.0.1")
      other = IPAddress::V4.new("192.168.0.2")
      this.<=>(other).should == -1
    end

    it "returns 1 if the other IPAddress::V4 has a lower integer address" do
      this = IPAddress::V4.new("192.168.0.2")
      other = IPAddress::V4.new("192.168.0.1")
      this.<=>(other).should == 1
    end

    it "returns 0 if the other IPAddress::V4 has the same integer address" do
      this = IPAddress::V4.new("192.168.0.1")
      other = IPAddress::V4.new("192.168.0.1")
      this.<=>(other).should == 0
    end
  end

  describe "#==" do
    it "is true if the other IPAddress::V4 has the same address and mask size" do
      this = IPAddress::V4.new("192.168.0.0/24")
      other = IPAddress::V4.new("192.168.0.0/24")
      this.should == other
    end

    it "is false if the other IPAddress::V4 has a different address" do
      this = IPAddress::V4.new("192.168.0.1/24")
      other = IPAddress::V4.new("192.168.0.2/24")
      this.should_not == other
    end

    it "is false if the other IPAddress::V4 has a different mask size" do
      this = IPAddress::V4.new("192.168.0.1/24")
      other = IPAddress::V4.new("192.168.0.2/28")
      this.should_not == other
    end
  end

  describe "#address" do
    it "returns the address as a dotted quad string if :string is given" do
      ip = IPAddress::V4.new("192.168.0.0/30")
      ip.address(:string).should == "192.168.0.0"
    end

    it "returns the address as an integer bitstring if :bits is given" do
      ip = IPAddress::V4.new("192.168.0.4/32")
      ip.address(:bits).should == 3232235524
    end

    it "defaults to :string if no argument is given" do
      ip = IPAddress::V4.new("192.168.0.0/27")
      ip.address.should == ip.address(:string)
    end

    it "raises an ArgumentError if an unrecognized presentation is given" do
      ip = IPAddress::V4.new("192.168.0.0/27")
      expect { ip.address(:wombat) }.to raise_error(ArgumentError)
    end
  end

  describe "#adjacent?" do
    it "is true if the other IPAddress::V4's network immediately follows this one" do
      this = IPAddress::V4.new("192.168.0.0/28")
      other = IPAddress::V4.new("192.168.0.16/28")
      this.adjacent?(other).should be_true
    end

    it "is true if the other IPAddress::V4's network immediately precedes this one" do
      this = IPAddress::V4.new("192.168.0.0/28")
      other = IPAddress::V4.new("192.167.255.254/28")
      this.adjacent?(other).should be_true
    end

    it "is false if the other IPAddress::V4's network includes this one" do
      this = IPAddress::V4.new("192.168.0.16/28")
      other = IPAddress::V4.new("192.168.0.0/24")
      this.adjacent?(other).should be_false
    end

    it "is false if the other IPAddress::V4's network is included in this one" do
      this = IPAddress::V4.new("192.168.0.16/28")
      other = IPAddress::V4.new("192.168.0.0/24")
      this.adjacent?(other).should be_false
    end

    it "is false for two host addresses with the same address" do
      this = IPAddress::V4.new("192.168.0.1")
      other = IPAddress::V4.new("192.168.0.1")
      this.adjacent?(other).should be_false
    end
  end

  describe "#broadcast" do
    it "returns the broadcast address as an IPAddress::V4 if :instance is given" do
      ip = IPAddress::V4.new("192.168.0.0/24")
      ip.broadcast(:instance).should == IPAddress::V4.new("192.168.0.255/24")
    end

    it "returns the broadcast address as an integer bitstring if :bits is given" do
      ip = IPAddress::V4.new("192.168.0.0/24")
      ip.broadcast(:bits).should == 3232235775
    end

    it "returns the broadcast address as a dotted quad string if :string is given" do
      ip = IPAddress::V4.new("192.168.0.0/24")
      ip.broadcast(:string).should == "192.168.0.255"
    end

    it "defaults to :instance if no presentation is given" do
      ip = IPAddress::V4.new("192.168.0.0/24")
      ip.broadcast.should == IPAddress::V4.new("192.168.0.255/24")
    end

    it "returns itself if it is a broadcast address" do
      ip = IPAddress::V4.new("192.168.0.255/24")
      ip.broadcast.should equal(ip)
    end
  end

  describe "#each" do
    it "iterates over each address in the network, including network and broadcast address, if :address is given" do
      ip = IPAddress::V4.new("192.168.0.0/30")
      expected_addresses = [0, 1, 2, 3].collect { |i| IPAddress::V4.new("192.168.0.#{i}/30") }
      addresses = []
      ip.each(:address) { |i| addresses << i }
      addresses.should == expected_addresses
    end

    it "iterates over each host address in the network, excluding network and broadcast address, if :host is given" do
      ip = IPAddress::V4.new("192.168.0.0/30")
      expected_addresses = [1, 2].collect { |i| IPAddress::V4.new("192.168.0.#{i}/30") }
      addresses = []
      ip.each(:host) { |i| addresses << i }
      addresses.should == expected_addresses
    end

    it "defaults to :host if no argument is given" do
      ip = IPAddress::V4.new("192.168.0.0/30")
      expected_addresses = []
      ip.each(:host) { |i| expected_addresses << i }
      addresses = []
      ip.each { |i| addresses << i }
      addresses.should == expected_addresses
    end

    it "raises ArgumentError if an unknown argument is given" do
      ip = IPAddress::V4.new("192.168.0.0/30")
      expect { ip.each(:wombat) { |i| true } }.to raise_error(ArgumentError)
    end

    it "preserves its own mask in the instances yielded to the caller's block" do
      ip = IPAddress::V4.new("192.168.0.0/30")
      addresses = []
      ip.each { |i| addresses << i }
      addresses.collect(&:mask).should == [30, 30]
    end

    it "yields itself once if it is a /32" do
      addresses = []
      ip = IPAddress::V4.new("192.168.0.1/32")
      ip.each { |i| addresses << i }
      addresses.should have(1).element
      addresses[0].should equal(ip)
    end
  end

  describe "#follow?" do
    it "is true if the other IPAddress::V4's network immediately precedes this one" do
      IPAddress::V4.new("192.168.1.0/24").follow?(IPAddress::V4.new("192.168.0.0/24")).should be_true
    end

    it "is false if the other IPAddress::V4's network does not immediately precede this one" do
      IPAddress::V4.new("192.168.1.2/31").follow?(IPAddress::V4.new("192.168.0.0/24")).should be_false
    end
  end

  describe "#host?" do
    it "is true if the mask size is 32" do
      ip = IPAddress::V4.new("192.168.0.1/32")
      ip.host?.should be_true
    end

    it "is true if the mask size is 0" do
      ip = IPAddress::V4.new("0.0.0.0/0")
      ip.host?.should be_true
    end

    it "is false if the address is the same as the masked address" do
      ip = IPAddress::V4.new("192.168.0.0/24")
      ip.host?.should be_false
    end

    it "is true if the address is the same as the masked address but the mask size is 32" do
      ip = IPAddress::V4.new("192.168.0.0/32")
      ip.host?.should be_true
    end

    it "is true if the address is the same as the masked address but the mask size is 0" do
      ip = IPAddress::V4.new("192.168.0.0/0")
      ip.host?.should be_true
    end
  end

  describe "#include?" do
    it "is true if the other IPAddress::V4 is a host in this network" do
      network = IPAddress::V4.new("192.168.0.16/28")
      ip = IPAddress::V4.new("192.168.0.17/32")
      network.include?(ip).should be_true
    end

    it "is false if the other IPAddress::V4 is a host outside this network" do
      network = IPAddress::V4.new("192.168.0.16/28")
      ip = IPAddress::V4.new("192.168.0.1/32")
      network.include?(ip).should be_false
    end

    it "is true if the other IPAddress::V4 is a network that fits inside this network" do
      network = IPAddress::V4.new("192.168.0.16/28")
      ip = IPAddress::V4.new("192.168.0.24/29")
      network.include?(ip).should be_true
    end

    it "is false if the other IPAddress::V4 is a network that does not fit inside this network" do
      network = IPAddress::V4.new("192.168.0.16/28")
      ip = IPAddress::V4.new("192.168.0.0/28")
      network.include?(ip).should be_false
    end

    it "is true if the other IPAddress::V4 is a host in this network but its network does not fit inside this network" do
      network = IPAddress::V4.new("192.168.0.16/28")
      ip = IPAddress::V4.new("192.168.0.17/24")
      network.include?(ip).should be_true
    end

    it "is true if this is the unspecified (wildcard) address" do
      wildcard = IPAddress::V4.new("0.0.0.0/0")
      ip = IPAddress::V4.new("192.168.0.1")
      wildcard.include?(ip).should be_true
    end
  end

  describe "#mask" do
    it "returns the mask size if :size is given" do
      ip = IPAddress::V4.new("192.168.0.0/27")
      ip.mask(:size).should == 27
    end

    it "returns a dotted quad string if :string is given" do
      ip = IPAddress::V4.new("192.168.0.0/27")
      ip.mask(:string).should == "255.255.255.224"
    end

    it "returns an integer bitmask if :bits is given" do
      ip = IPAddress::V4.new("192.168.0.0/27")
      ip.mask(:bits).should == 4294967264 # (2**27 - 1) left-shifted 5 bits
    end

    it "defaults to :size if no argument is given" do
      ip = IPAddress::V4.new("192.168.0.0/27")
      ip.mask.should == ip.mask(:size)
    end

    it "raises an ArgumentError if an unrecognized presentation is given" do
      ip = IPAddress::V4.new("192.168.0.0/27")
      expect { ip.mask(:wombat) }.to raise_error(ArgumentError)
    end
  end

  describe "#network" do
    it "returns the network address as an IPAddress::V4 if :instance is given" do
      ip = IPAddress::V4.new("192.168.0.1/24")
      ip.network(:instance).should == IPAddress::V4.new("192.168.0.0/24")
    end

    it "returns the network address as an integer bitstring if :bits is given" do
      ip = IPAddress::V4.new("192.168.0.1/24")
      ip.network(:bits).should == 3232235520
    end

    it "returns the network address as a dotted quad string if :string is given" do
      ip = IPAddress::V4.new("192.168.0.1/24")
      ip.network(:string).should == "192.168.0.0"
    end

    it "defaults to :instance if presentation is not given" do
      ip = IPAddress::V4.new("192.168.0.1/24")
      ip.network.should == IPAddress::V4.new("192.168.0.0/24")
    end

    it "raises ArgumentError if an unknown presentation is given" do
      ip = IPAddress::V4.new("192.168.0.1/24")
      expect { ip.network(:wombat) }.to raise_error(ArgumentError)
    end

    it "returns itself if it is a network address" do
      ip = IPAddress::V4.new("192.168.0.0/24")
      ip.network.should equal(ip)
    end
  end

  describe "#network?" do
    it "is false if the mask size is 32" do
      ip = IPAddress::V4.new("192.168.0.1/32")
      ip.network?.should be_false
    end

    it "is false if the mask size is 0" do
      ip = IPAddress::V4.new("0.0.0.0/0")
      ip.network?.should be_false
    end

    it "is true if the address is the same as the masked address" do
      ip = IPAddress::V4.new("192.168.0.0/24")
      ip.network?.should be_true
    end

    it "is false if the address is the same as the masked address but the mask size is 32" do
      ip = IPAddress::V4.new("192.168.0.0/32")
      ip.network?.should be_false
    end

    it "is false if the address is the same as the masked address but the mask size is 0" do
      ip = IPAddress::V4.new("192.168.0.0/0")
      ip.network?.should be_false
    end
  end

  describe "#precede?" do
    it "is true if the other IPAddress::V4's network immediately follows this one" do
      IPAddress::V4.new("192.168.0.0/24").precede?(IPAddress::V4.new("192.168.1.0/24")).should be_true
    end

    it "is false if the other IPAddress::V4's network does not immediately follow this one" do
      IPAddress::V4.new("192.168.0.0/24").precede?(IPAddress::V4.new("192.168.1.2/31")).should be_false
    end
  end

  describe "#to_s" do
    it "returns a CIDR string" do
      ip = IPAddress::V4.new("192.168.0.0/24")
      ip.to_s.should == "192.168.0.0/24"
    end
  end

  describe ".aggregate" do
    it "returns an array of one IPAddress::V4 that aggregates two given addresses if they are adjacent" do
      aggregates = IPAddress::V4.aggregate [IPAddress::V4.new("192.168.0.0/28"), IPAddress::V4.new("192.168.0.16/28")]
      aggregates.should == [IPAddress::V4.new("192.168.0.0/27")]
    end

    it "returns an array of two IPAddress::V4's that aggregate two given pairs of adjacent addresses" do
      a = %w{ 192.168.0.0 192.168.0.16 192.168.0.64 192.168.0.80 }.collect { |i| IPAddress::V4.new("#{i}/28") }
      aggregates = IPAddress::V4.aggregate(a)
      aggregates.should == [IPAddress::V4.new("192.168.0.0/27"), IPAddress::V4.new("192.168.0.64/27")]
    end

    it "returns an array of one IPAddress::V4 that aggregates two given addresses if one includes the other" do
      a = [IPAddress::V4.new("192.168.0.0/24"), IPAddress::V4.new("192.168.0.64/28")]
      aggreggates = IPAddress::V4.aggregate(a)
      aggreggates.should == [IPAddress::V4.new("192.168.0.0/24")]
    end

    it "avoids aggregation that would inappropriately lower the network address" do
      a = [IPAddress::V4.new("192.168.0.16/28"), IPAddress::V4.new("192.168.0.32/28")]
      aggregates = IPAddress::V4.aggregate(a)
      aggregates.should == a # Aggregation not possible
    end

    it "copes with diminishing network sizes in successive adjacent networks" do
      a = %w{ 192.168.0.0/30 192.168.0.4/31 192.168.0.6/31 }.map {|i| IPAddress::V4.new(i) }
      aggregates = IPAddress::V4.aggregate(a)
      aggregates.should == [ IPAddress::V4.new("192.168.0.0/29") ]
    end

    it "reviews current set for further opportunities each time an aggregation is performed" do
      nets = %w{
        192.168.0.0/24
        192.168.1.0/24
        192.168.2.0/25
        192.168.2.128/25
        192.168.3.0/26
        192.168.3.64/27
        192.168.3.96/28
        192.168.3.112/29
        192.168.3.120/30
        192.168.3.124/31
        192.168.3.126/32
        192.168.3.127/32
        192.168.3.128/31
        192.168.3.130/31
        192.168.3.132/30
        192.168.3.136/29
        192.168.3.144/28
        192.168.3.160/27
        192.168.3.192/26
      }.collect {|s| IPAddress::V4.new(s) }
      IPAddress::V4::aggregate(nets).should == [IPAddress::V4.new("192.168.0.0/22")]
    end

    it "copes with unordered addresses if input order is given as :unsorted" do
      a = %w{ 192.168.0.64 192.168.0.16 192.168.0.80 192.168.0.0 }.collect { |i| IPAddress::V4.new("#{i}/28") }
      aggregates = IPAddress::V4.aggregate(a, :unsorted)
      aggregates.should == [IPAddress::V4.new("192.168.0.0/27"), IPAddress::V4.new("192.168.0.64/27")]
    end

    it "skips the sort operation if input order is given as :presorted" do
      a = %w{ 192.168.0.0 192.168.0.16 192.168.0.64 192.168.0.80 }.collect { |i| IPAddress::V4.new("#{i}/28") }
      a.should_not_receive(:sort)
      aggregates = IPAddress::V4.aggregate(a, :presorted)
      aggregates.should == [IPAddress::V4.new("192.168.0.0/27"), IPAddress::V4.new("192.168.0.64/27")]
    end

    it "defaults to :unsorted if no input order is given" do
      a = %w{ 192.168.0.64 192.168.0.16 192.168.0.80 192.168.0.0 }.collect { |i| IPAddress::V4.new("#{i}/28") }
      IPAddress::V4.aggregate(a).should == IPAddress::V4.aggregate(a, :unsorted)
    end

    it "raises an ArgumentError if an unknown input order is given" do
      a = %w{ 192.168.0.0 192.168.0.16 }.collect { |i| IPAddress::V4.new("#{i}/28") }
      expect { IPAddress::V4.aggregate(a, :wombat) }.to raise_error(ArgumentError)
    end

    it "does not modify the passed array or its contents" do
      a = %w{ 192.168.0.64 192.168.0.16 192.168.0.80 192.168.0.0 }.collect { |i| IPAddress::V4.new("#{i}/28").freeze }
      a.freeze
      expect { aggregates = IPAddress::V4.aggregate(a) }.to_not raise_error
    end

    it "avoids unnecessary instance creation by reusing unaggregated instances from the passed array" do
      a = %w{ 192.168.0.0 192.168.0.16 192.168.0.48 192.168.0.64 192.168.0.80 }.collect { |i| IPAddress::V4.new("#{i}/28") }
      aggregates = IPAddress::V4.aggregate(a)
      aggregates[1].should equal(a[2]) # 192.168.0.48/28 was not aggregated
    end
  end

  describe "include Enumerable" do
    it "supports #collect even though its #each method takes an optional argument" do
      ip = IPAddress::V4.new("192.168.0.0/30")
      masks = ip.collect { |i| i.address(:string) }
      masks.should == ["192.168.0.1", "192.168.0.2"]
    end
  end
end
