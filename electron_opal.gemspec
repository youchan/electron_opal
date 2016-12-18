# -*- encoding: utf-8 -*-

require 'date'

Gem::Specification.new do |s|
  s.name        = "electron_opal"
  s.version     = "0.0.1" 
  s.date        = Date.today
  s.summary     = "Lightweigt Ruby wrapper around the geat electron desktop application engine"
  s.description = "Lightweigt Ruby wrapper around the geat electron desktop application engine"
  s.authors     = ["Jannis Hübl"]
  s.email       = "jannis.huebl@gmail.com"
  s.homepage    = "https://github.com/jannishuebl/electron_opal"
  s.license     = "MIT"
  s.files       = Dir.glob("lib/**/*").concat(Dir.glob("opal/**/*")) << "README.md" << "LICENSE" 

  s.add_dependency "opal-activesupport"
  s.add_dependency "opal-browser"
  s.add_dependency "opal", "~> 0.10.0"
  s.add_dependency "sprockets", "~> 3.2.0"
  s.add_dependency "opal-jquery"
  s.add_dependency "opal-vienna"
  s.add_dependency "activesupport"
  s.add_development_dependency "tilt", "~> 2.0.1"
  s.add_development_dependency "rack", "~> 1.6.4"
end
