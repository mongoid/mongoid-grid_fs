## mongoid-grid_fs.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "mongoid-grid_fs"
  spec.version = "1.2.1"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "mongoid-grid_fs"
  spec.description = "a mongoid 3/moped compatible implementation of the grid_fs specification"

  spec.files =
["README.md",
 "Rakefile",
 "lib",
 "lib/mongoid-grid_fs.rb",
 "mongoid-grid_fs.gemspec",
 "test",
 "test/helper.rb",
 "test/mongoid-grid_fs_test.rb",
 "test/testing.rb"]

  spec.executables = []
  
  spec.require_path = "lib"

  spec.test_files = nil

  
    spec.add_dependency(*["mongoid", "~> 3.0.1"])
  
    spec.add_dependency(*["mime-types", "~> 1.19"])
  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/mongoid-grid_fs"
end
