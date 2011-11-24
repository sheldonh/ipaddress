require 'spec_helper'

describe "IP::Aggregator" do

  before :each do
    @aggregator = IP::Aggregator.new
  end

  context "aggregating IP::V4 instances" do

    describe "#aggregate" do
      it "returns an array of one IP::V4 that aggregates two given addresses if they are adjacent" do
        aggregates = @aggregator.aggregate [IP::V4.new("192.168.0.0/28"), IP::V4.new("192.168.0.16/28")]
        aggregates.should == [IP::V4.new("192.168.0.0/27")]
      end

      it "returns an array of two IP::V4's that aggregate two given pairs of adjacent addresses" do
        a = %w{ 192.168.0.0 192.168.0.16 192.168.0.64 192.168.0.80 }.collect { |i| IP::V4.new("#{i}/28") }
        aggregates = @aggregator.aggregate(a)
        aggregates.should == [IP::V4.new("192.168.0.0/27"), IP::V4.new("192.168.0.64/27")]
      end

      it "returns an array of one IP::V4 that aggregates two given addresses if one includes the other" do
        a = [IP::V4.new("192.168.0.0/24"), IP::V4.new("192.168.0.64/28")]
        aggreggates = @aggregator.aggregate(a)
        aggreggates.should == [IP::V4.new("192.168.0.0/24")]
      end

      it "avoids aggregation that would inappropriately lower the network address" do
        a = [IP::V4.new("192.168.0.16/28"), IP::V4.new("192.168.0.32/28")]
        aggregates = @aggregator.aggregate(a)
        aggregates.should == a # Aggregation not possible
      end

      it "copes with diminishing network sizes in successive adjacent networks" do
        a = %w{ 192.168.0.0/30 192.168.0.4/31 192.168.0.6/31 }.map {|i| IP::V4.new(i) }
        aggregates = @aggregator.aggregate(a)
        aggregates.should == [ IP::V4.new("192.168.0.0/29") ]
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
        }.collect {|s| IP::V4.new(s) }
        IP::V4::aggregate(nets).should == [IP::V4.new("192.168.0.0/22")]
      end

      it "copes with unordered addresses if input order is given as :unsorted" do
        a = %w{ 192.168.0.64 192.168.0.16 192.168.0.80 192.168.0.0 }.collect { |i| IP::V4.new("#{i}/28") }
        aggregates = @aggregator.aggregate(a, :unsorted)
        aggregates.should == [IP::V4.new("192.168.0.0/27"), IP::V4.new("192.168.0.64/27")]
      end

      it "skips the sort operation if input order is given as :presorted" do
        a = %w{ 192.168.0.0 192.168.0.16 192.168.0.64 192.168.0.80 }.collect { |i| IP::V4.new("#{i}/28") }
        a.should_not_receive(:sort)
        aggregates = @aggregator.aggregate(a, :presorted)
        aggregates.should == [IP::V4.new("192.168.0.0/27"), IP::V4.new("192.168.0.64/27")]
      end

      it "defaults to :unsorted if no input order is given" do
        a = %w{ 192.168.0.64 192.168.0.16 192.168.0.80 192.168.0.0 }.collect { |i| IP::V4.new("#{i}/28") }
        @aggregator.aggregate(a).should == @aggregator.aggregate(a, :unsorted)
      end

      it "raises an ArgumentError if an unknown input order is given" do
        a = [ IP::V4.new("192.168.0.0/28"), IP::V4.new("192.168.0.16/28") ]
        expect { @aggregator.aggregate(a, :wombat) }.to raise_error(ArgumentError)
      end

      it "does not modify the passed array or its contents" do
        a = %w{ 192.168.0.64 192.168.0.16 192.168.0.80 192.168.0.0 }.collect { |i| IP::V4.new("#{i}/28").freeze }
        a.freeze
        expect { aggregates = @aggregator.aggregate(a) }.to_not raise_error
      end

      it "avoids unnecessary instance creation by reusing unaggregated instances from the passed array" do
        a = %w{ 192.168.0.0 192.168.0.16 192.168.0.48 192.168.0.64 192.168.0.80 }.collect { |i| IP::V4.new("#{i}/28") }
        aggregates = @aggregator.aggregate(a)
        aggregates[1].should equal(a[2]) # 192.168.0.48/28 was not aggregated
      end

    end

  end

  context "aggregating IP::V6 instances" do

    describe "#aggregate" do
      it "returns an array of one IP::V6 that aggregates two given addresses if they are adjacent" do
        aggregates = @aggregator.aggregate [IP::V6.new("fc00::/8"), IP::V6.new("fd00::/8")]
        aggregates.should == [IP::V6.new("fc00::/7")]
      end

      it "returns an array of two IP::V6's that aggregate two given pairs of adjacent addresses" do
        a = %w{ fc00:0:: fc00:1:: fd00:0:: fd00:1:: }.collect { |i| IP::V6.new("#{i}/32") }
        aggregates = @aggregator.aggregate(a)
        aggregates.should == [IP::V6.new("fc00:0::/31"), IP::V6.new("fd00:0::/31")]
      end

      it "returns an array of one IP::V6 that aggregates two given addresses if one includes the other" do
        a = [IP::V6.new("fc00::/8"), IP::V6.new("fc80::/9")]
        aggreggates = @aggregator.aggregate(a)
        aggreggates.should == [IP::V6.new("fc00::/8")]
      end

      it "avoids aggregation that would inappropriately lower the network address" do
        a = [IP::V6.new("fc80::/9"), IP::V6.new("fd00::/9")]
        aggregates = @aggregator.aggregate(a)
        aggregates.should == a # Aggregation not possible
      end

      it "copes with diminishing network sizes in successive adjacent networks" do
        a = %w{ fc00::/8 fd00::/9 fd80::/9 }.map {|i| IP::V6.new(i) }
        aggregates = @aggregator.aggregate(a)
        aggregates.should == [ IP::V6.new("fc00::/7") ]
      end

      it "reviews current set for further opportunities each time an aggregation is performed" do
        nets = %w{
          fc00:0:0000::/32
          fc00:1:0000::/32
          fc00:2:0000::/33
          fc00:2:8000::/33
          fc00:3:0000::/34
          fc00:3:4000::/35
          fc00:3:6000::/36
          fc00:3:7000::/37
          fc00:3:7800::/38
          fc00:3:7c00::/39
          fc00:3:7e00::/40
          fc00:3:7f00::/40
          fc00:3:8000::/39
          fc00:3:8200::/39
          fc00:3:8400::/38
          fc00:3:8800::/37
          fc00:3:9000::/36
          fc00:3:a000::/35
          fc00:3:c000::/34
        }.collect {|s| IP::V6.new(s) }
        IP::V6::aggregate(nets).should == [IP::V6.new("fc00:0:0000::/30")]
      end

      it "copes with unordered addresses if input order is given as :unsorted" do
        nets = %w{ fc00:5::/32 fc00:1::/32 fc00:4::/32 fc00:0::/32 }.collect { |s| IP::V6.new(s) }
        aggregates = @aggregator.aggregate(nets, :unsorted)
        aggregates.should == [IP::V6.new("fc00:0::/31"), IP::V6.new("fc00:4::/31")]
      end

      it "skips the sort operation if input order is given as :presorted" do
        nets = %w{ fc00:0::/32 fc00:1::/32 fc00:4::/32 fc00:5::/32 }.collect { |s| IP::V6.new(s) }
        nets.should_not_receive(:sort)
        aggregates = @aggregator.aggregate(nets, :presorted)
        aggregates.should == [IP::V6.new("fc00:0::/31"), IP::V6.new("fc00:4::/31")]
      end

      it "defaults to :unsorted if no input order is given" do
        nets = %w{ fc00:5::/32 fc00:1::/32 fc00:4::/32 fc00:0::/32 }.collect { |s| IP::V6.new(s) }
        @aggregator.aggregate(nets).should == @aggregator.aggregate(nets, :unsorted)
      end

      it "raises an ArgumentError if an unknown input order is given" do
        nets = [ IP::V6.new("fc00:0::/32"), IP::V6.new("fc00:1::/32") ]
        expect { @aggregator.aggregate(nets, :wombat) }.to raise_error(ArgumentError)
      end

      it "does not modify the passed array or its contents" do
        nets = %w{ fc00:0::/32 fc00:1::/32 }.collect { |s| IP::V6.new(s).freeze }
        nets.freeze
        expect { aggregates = @aggregator.aggregate(nets) }.to_not raise_error
      end

      it "avoids unnecessary instance creation by reusing unaggregated instances from the passed array" do
        nets = %w{ fc00:0::/32 fc00:1::/32 fc00:4::/32 fc00:6::/32 fc00:7::/32 }.collect { |s| IP::V6.new(s) }
        aggregates = @aggregator.aggregate(nets)
        aggregates[1].should equal(nets[2]) # fc00:4::/32 was not aggregated
      end

    end

  end

  context "aggregating a mix of IP::V4 and IP::V6 instances" do

    describe "#aggregate" do

      it "raises an exception if given two instances of differing classes" do
        nets = [ IP::V4.new("192.168.0.0/24"), IP::V6.new("fc00::/7") ]
        expect { @aggregator.aggregate(nets) }.to raise_error(ArgumentError)
      end

    end

  end

end
