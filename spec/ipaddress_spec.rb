require 'spec_helper'

describe "IPAddress" do
  describe "#new" do
    it "takes a CIDR string" do
      expect { IPAddress.new("192.168.0.0/24") }.to_not raise_error
    end

    it "takes an address/mask dotted quad string" do
      ip = IPAddress.new("192.168.0.0/255.255.255.0")
      ip.mask.should == IPAddress.new("192.168.0.0/24").mask
    end

    it "takes an unmasked address string and assumes a mask size of 32" do
      ip = IPAddress.new("192.168.0.1")
      ip.mask.should == 32
    end

    it "takes an integer address and mask size" do
      ip = IPAddress.new(3232235520, 24)
      ip.address.should == "192.168.0.0"
      ip.mask.should == 24
    end

    it "raises an ArgumentError if given no arguments" do
      expect { IPAddress.new }.to raise_error(ArgumentError)
    end

    it "raises an ArgumentError if given more than 2 arguments" do
      expect { IPAddress.new(3232235520, 24, :wombat) }.to raise_error(ArgumentError)
    end
  end

  describe "#<=>" do
    it "returns -1 if the other IPAddress has an higher integer address" do
      this = IPAddress.new("192.168.0.1")
      other = IPAddress.new("192.168.0.2")
      this.<=>(other).should == -1
    end

    it "returns 1 if the other IPAddress has a lower integer address" do
      this = IPAddress.new("192.168.0.2")
      other = IPAddress.new("192.168.0.1")
      this.<=>(other).should == 1
    end

    it "returns 0 if the other IPAddress has the same integer address" do
      this = IPAddress.new("192.168.0.1")
      other = IPAddress.new("192.168.0.1")
      this.<=>(other).should == 0
    end
  end

  describe "#==" do
    it "is true if the other IPAddress has the same address and mask size" do
      this = IPAddress.new("192.168.0.0/24")
      other = IPAddress.new("192.168.0.0/24")
      this.should == other
    end

    it "is false if the other IPAddress has a different address" do
      this = IPAddress.new("192.168.0.1/24")
      other = IPAddress.new("192.168.0.2/24")
      this.should_not == other
    end

    it "is false if the other IPAddress has a different mask size" do
      this = IPAddress.new("192.168.0.1/24")
      other = IPAddress.new("192.168.0.2/28")
      this.should_not == other
    end
  end

  describe "#mask" do
    it "returns the mask size if :size is given" do
      ip = IPAddress.new("192.168.0.0/27")
      ip.mask(:size).should == 27
    end

    it "returns a dotted quad string if :dotted is given" do
      ip = IPAddress.new("192.168.0.0/27")
      ip.mask(:dotted).should == "255.255.255.224"
    end

    it "returns an integer bitmask if :bits is given" do
      ip = IPAddress.new("192.168.0.0/27")
      ip.mask(:bits).should == 4294967264 # (2**27 - 1) left-shifted 5 bits
    end

    it "defaults to :size if no argument is given" do
      ip = IPAddress.new("192.168.0.0/27")
      ip.mask.should == ip.mask(:size)
    end

    it "raises an ArgumentError if an unrecognized presentation is given" do
      ip = IPAddress.new("192.168.0.0/27")
      expect { ip.mask(:wombat) }.to raise_error(ArgumentError)
    end
  end

  describe "#address" do
    it "returns a dotted quad string if :dotted is given" do
      ip = IPAddress.new("192.168.0.0/30")
      ip.address(:dotted).should == "192.168.0.0"
    end

    it "returns an integer bitmask if :bits is given" do
      ip = IPAddress.new("192.168.0.4/32")
      ip.address(:bits).should == 3232235524
    end

    it "defaults to :dotted if no argument is given" do
      ip = IPAddress.new("192.168.0.0/27")
      ip.address.should == ip.address(:dotted)
    end

    it "raises an ArgumentError if an unrecognized presentation is given" do
      ip = IPAddress.new("192.168.0.0/27")
      expect { ip.address(:wombat) }.to raise_error(ArgumentError)
    end
  end

  describe "#broadcast" do
    it "returns an IPAddress that represents the broadcast address" do
      ip = IPAddress.new("192.168.0.0/24")
      ip.broadcast.should == IPAddress.new("192.168.0.255/24")
    end

    it "returns itself if it is a broadcast address" do
      ip = IPAddress.new("192.168.0.255/24")
      ip.broadcast.should equal(ip)
    end
  end

  describe "#each" do
    it "iterates over each address in the network, including network and broadcast address, if :address is given" do
      ip = IPAddress.new("192.168.0.0/30")
      expected_addresses = [0, 1, 2, 3].collect { |i| IPAddress.new("192.168.0.#{i}/30") }
      addresses = []
      ip.each(:address) { |i| addresses << i }
      addresses.should == expected_addresses
    end

    it "iterates over each host address in the network, excluding network and broadcast address, if :host is given" do
      ip = IPAddress.new("192.168.0.0/30")
      expected_addresses = [1, 2].collect { |i| IPAddress.new("192.168.0.#{i}/30") }
      addresses = []
      ip.each(:host) { |i| addresses << i }
      addresses.should == expected_addresses
    end

    it "defaults to :host if no argument is given" do
      ip = IPAddress.new("192.168.0.0/30")
      expected_addresses = []
      ip.each(:host) { |i| expected_addresses << i }
      addresses = []
      ip.each { |i| addresses << i }
      addresses.should == expected_addresses
    end

    it "preserves its own mask in the instances yielded to the caller's block" do
      ip = IPAddress.new("192.168.0.0/30")
      addresses = []
      ip.each { |i| addresses << i }
      addresses.collect(&:mask).should == [30, 30]
    end

    it "raises ArgumentError if an unknown argument is given" do
      ip = IPAddress.new("192.168.0.0/30")
      expect { ip.each(:wombat) { |i| true } }.to raise_error(ArgumentError)
    end
  end

  describe "#host?" do
    it "is true if the mask size is 32" do
      ip = IPAddress.new("192.168.0.1/32")
      ip.host?.should be_true
    end

    it "is true if the mask size is 0" do
      ip = IPAddress.new("0.0.0.0/0")
      ip.host?.should be_true
    end

    it "is false if the address is the same as the masked address" do
      ip = IPAddress.new("192.168.0.0/24")
      ip.host?.should be_false
    end

    it "is true if the address is the same as the masked address but the mask size is 32" do
      ip = IPAddress.new("192.168.0.0/32")
      ip.host?.should be_true
    end

    it "is true if the address is the same as the masked address but the mask size is 0" do
      ip = IPAddress.new("192.168.0.0/0")
      ip.host?.should be_true
    end
  end

  describe "#include?" do
    it "is true if the other IPAddress is a host in this network" do
      network = IPAddress.new("192.168.0.16/28")
      ip = IPAddress.new("192.168.0.17/32")
      network.include?(ip).should be_true
    end

    it "is false if the other IPAddress is a host outside this network" do
      network = IPAddress.new("192.168.0.16/28")
      ip = IPAddress.new("192.168.0.1/32")
      network.include?(ip).should be_false
    end

    it "is true if the other IPAddress is a network that fits inside this network" do
      network = IPAddress.new("192.168.0.16/28")
      ip = IPAddress.new("192.168.0.24/29")
      network.include?(ip).should be_true
    end

    it "is false if the other IPAddress is a network that does not fit inside this network" do
      network = IPAddress.new("192.168.0.16/28")
      ip = IPAddress.new("192.168.0.0/28")
      network.include?(ip).should be_false
    end

    it "is true if the other IPAddress is a host in this network but its network does not fit inside this network" do
      network = IPAddress.new("192.168.0.16/28")
      ip = IPAddress.new("192.168.0.17/24")
      network.include?(ip).should be_true
    end

    it "is true if this is the unspecified (wildcard) address" do
      wildcard = IPAddress.new("0.0.0.0/0")
      ip = IPAddress.new("192.168.0.1")
      wildcard.include?(ip).should be_true
    end
  end

  describe "#network" do
    it "returns an IPAddress that represents the address masked with the network mask" do
      ip = IPAddress.new("192.168.0.1/24")
      ip.network.should == IPAddress.new("192.168.0.0/24")
    end

    it "returns itself if it is a network address" do
      ip = IPAddress.new("192.168.0.0/24")
      ip.network.should equal(ip)
    end
  end

  describe "#network?" do
    it "is false if the mask size is 32" do
      ip = IPAddress.new("192.168.0.1/32")
      ip.network?.should be_false
    end

    it "is false if the mask size is 0" do
      ip = IPAddress.new("0.0.0.0/0")
      ip.network?.should be_false
    end

    it "is true if the address is the same as the masked address" do
      ip = IPAddress.new("192.168.0.0/24")
      ip.network?.should be_true
    end

    it "is false if the address is the same as the masked address but the mask size is 32" do
      ip = IPAddress.new("192.168.0.0/32")
      ip.network?.should be_false
    end

    it "is false if the address is the same as the masked address but the mask size is 0" do
      ip = IPAddress.new("192.168.0.0/0")
      ip.network?.should be_false
    end
  end

  describe "#to_s" do
    it "returns a CIDR string" do
      ip = IPAddress.new("192.168.0.0/24")
      ip.to_s.should == "192.168.0.0/24"
    end
  end

  describe "include Enumerable" do
    it "supports #collect even though its #each method takes an optional argument" do
      ip = IPAddress.new("192.168.0.0/30")
      masks = ip.collect { |i| i.address(:dotted) }
      masks.should == ["192.168.0.1", "192.168.0.2"]
    end
  end
end
