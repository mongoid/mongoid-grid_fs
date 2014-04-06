lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongoid/grid_fs/version'

Gem::Specification::new do |spec|
  spec.name         = "mongoid-grid_fs"
  spec.version      = Mongoid::GridFs::VERSION
  spec.authors      = ["Ara T. Howard"]
  spec.email        = ["ara.t.howard@gmail.com"]
  spec.platform     = Gem::Platform::RUBY
  spec.summary      = "A MongoDB GridFS implementation for Mongoid"
  spec.description  = "A pure Mongoid/Moped implementation of the MongoDB GridFS specification"
  spec.homepage     = "https://github.com/ahoward/mongoid-grid_fs"
  spec.license      = "Ruby"

  spec.files        = `git ls-files -z`.split("\x0")
  spec.executables  = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files   = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_path = "lib"

  spec.add_dependency(*["mongoid", ">= 3.0", "< 5.0"])
  spec.add_dependency(*["mime-types", ">= 1.0", "< 3.0"])
end
