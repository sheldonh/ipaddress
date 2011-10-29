#!/usr/bin/env ruby
#
# IPAddr.new("192.168.0.0/28")
# 1.270000   4.830000   6.100000 (  8.527111)
# IPAddr.new("192.168.0.0/255.255.255.240")
# 2.080000   9.870000  11.950000 ( 16.597943)
# IPAddress.new("192.168.0.0/28")
# 0.360000   0.010000   0.370000 (  0.516183)
# IPAddress.new("192.168.0.0/255.255.255.240")
# 0.610000   0.000000   0.610000 (  0.826877)

require 'benchmark'
require 'ipaddr'
$LOAD_PATH.unshift 'lib'
require 'ipaddress'

puts 'IPAddr.new("192.168.0.0/28")'
puts Benchmark.measure { 100000.times { IPAddr.new("192.168.0.0/28") } }
puts 'IPAddr.new("192.168.0.0/255.255.255.240")'
puts Benchmark.measure { 100000.times { IPAddr.new("192.168.0.0/255.255.255.240") } }
puts 'IPAddress.new("192.168.0.0/28")'
puts Benchmark.measure { 100000.times { IPAddress.new("192.168.0.0/28") } }
puts 'IPAddress.new("192.168.0.0/255.255.255.240")'
puts Benchmark.measure { 100000.times { IPAddress.new("192.168.0.0/255.255.255.240") } }
