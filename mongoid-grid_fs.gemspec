## mongoid-grid_fs.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "mongoid-grid_fs"
  spec.version = "2.0.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "mongoid-grid_fs"
  spec.description = "description: mongoid-grid_fs kicks the ass"
  spec.license = "Ruby"

  spec.files =
["Gemfile",
 "LICENSE",
 "README.md",
 "Rakefile",
 "config.rb",
 "gemfiles",
 "gemfiles/mongoid-3.0.gemfile",
 "gemfiles/mongoid-3.1.gemfile",
 "gemfiles/mongoid-4.0.gemfile",
 "lib",
 "lib/app",
 "lib/app/models",
 "lib/app/models/mongoid",
 "lib/app/models/mongoid/grid_fs",
 "lib/app/models/mongoid/grid_fs.rb",
 "lib/app/models/mongoid/grid_fs/fs",
 "lib/app/models/mongoid/grid_fs/fs/chunk.rb",
 "lib/app/models/mongoid/grid_fs/fs/file.rb",
 "lib/mongoid-grid_fs.rb",
 "mongoid-grid_fs.gemspec",
 "script",
 "script/shell",
 "test",
 "test/helper.rb",
 "test/mongoid-grid_fs_test.rb",
 "test/testing.rb"]

  spec.executables = []
  
  spec.require_path = "lib"

  spec.test_files = nil

  
    spec.add_dependency(*["mongoid", ">= 3.0", "< 5.0"])
  
    spec.add_dependency(*["mime-types", ">= 1.0", "< 3.0"])
  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/mongoid-grid_fs"
end
