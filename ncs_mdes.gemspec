# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ncs_navigator/mdes/version"

Gem::Specification.new do |s|
  s.name        = "ncs_mdes"
  s.version     = NcsNavigator::Mdes::VERSION
  s.authors     = ["Rhett Sutphin"]
  s.email       = ["r-sutphin@northwestern.edu"]
  s.homepage    = ""
  s.summary     = %q{A ruby API for various versions of the NCS MDES.}
  s.description = %q{
Provides a consistent ruby interface to the project metainformation in the
National Children's Study's Master Data Element Specification.
}

  s.files         = `git ls-files`.split("\n") - ['irb']
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'nokogiri', '~> 1.4'

  s.add_development_dependency 'rspec', '~> 2.6.0' # Can't use 2.7.0 due to #477
  s.add_development_dependency 'rake', '~> 0.9.2'
  s.add_development_dependency 'yard', '~> 0.7.2'
  s.add_development_dependency 'ci_reporter', '~> 1.6'
end
