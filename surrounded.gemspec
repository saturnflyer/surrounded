lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "surrounded/version"

Gem::Specification.new do |spec|
  spec.name = "surrounded"
  spec.version = Surrounded.version
  spec.authors = ["'Jim Gay'"]
  spec.email = ["jim@saturnflyer.com"]
  spec.description = "Gives an object implicit access to other objects in it's environment."
  spec.summary = "Create encapsulated environments for your objects."
  spec.homepage = "http://github.com/saturnflyer/surrounded"
  spec.license = "MIT"

  spec.files = Dir[
    "lib/**/*",
    "Rakefile",
    "README.md",
    "Changelog.md",
    "LICENSE.txt",
    "test/**/*",
    "surrounded.gemspec"
  ]
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "triad", ">= 0.3.0"

  spec.add_development_dependency "rake"
end
