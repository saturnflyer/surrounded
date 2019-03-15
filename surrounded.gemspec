# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'surrounded/version'

Gem::Specification.new do |spec|
  spec.name          = "surrounded"
  spec.version       = Surrounded.version
  spec.authors       = ["'Jim Gay'"]
  spec.email         = ["jim@saturnflyer.com"]
  spec.description   = %q{Gives an object implicit access to other objects in it's environment.}
  spec.summary       = %q{Create encapsulated environments for your objects.}
  spec.homepage      = "http://github.com/saturnflyer/surrounded"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "triad",  "~> 0.3.0"

  spec.add_development_dependency "rake"
end
