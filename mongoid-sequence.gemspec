## mongoid-sequence.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "mongoid-sequence"
  spec.version = "1.0.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "mongoid-sequence"
  spec.description = "a mongoid 3/moped compatible sequence generator for your models"

  spec.files =
["README.md",
 "Rakefile",
 "lib",
 "lib/mongoid-sequence.rb",
 "test",
 "test/helper.rb",
 "test/mongoid-sequence.rb",
 "test/mongoid-sequence_test.rb",
 "test/testing.rb"]

  spec.executables = []
  
  spec.require_path = "lib"

  spec.test_files = "test/mongoid-sequence.rb"

  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/mongoid-sequence"
end
