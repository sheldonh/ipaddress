#!/usr/bin/env ruby

require 'benchmark'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'ipaddress'

expected = []
nets = []

File.open File.join(File.dirname(__FILE__), 'ipnets.txt') do |io|
  io.each do |line|
    if line =~ /^(#\s*)?([\d\/.]+)$/
      comment, spec = $1, $2
      net = IPAddress::V4.new(spec)
      if comment
        expected <<  net
      else
        nets << net
      end
    else
      $stderr.puts "ignoring line #{io.lineno}: #{line}"
    end
  end
end

puts Benchmark.measure { 1000.times { IPAddress::V4::aggregate(nets) } }

aggregates = IPAddress::V4::aggregate(nets)
if expected == aggregates
  puts "  aggregation successful"
else
  puts "  aggregation failed:"
  puts "  expected #{expected.inspect}"
  puts "  received #{aggregates.inspect}"
end
