# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ipaddress/version"

Gem::Specification.new do |s|
  s.name        = "ipaddress"
  s.version     = IPAddress::VERSION
  s.authors     = ["Sheldon Hearn"]
  s.email       = ["sheldonh@starjuice.net"]
  s.homepage    = ""
  s.summary     = %q{Faster, more usable alternative to Ruby IPAddr}
  s.description = %q{Provides a faster and more usable IP address model than Ruby's IPAddr }

  s.rubyforge_project = "ipaddress"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency('rake', '~> 0.9.2')
  s.add_development_dependency('rspec', '~> 2.6.0')
end
