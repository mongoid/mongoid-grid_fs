## mongoid-grid_fs.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "mongoid-grid_fs"
  spec.version = "2.0.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "mongoid-grid_fs"
  spec.description = "description: mongoid-grid_fs kicks the ass"
  spec.license = "Ruby"

  spec.files = `git ls-files`.split("\n")
  spec.test_files = `git ls-files test`.split("\n")

  spec.executables = []
  
  spec.require_path = "lib"

  spec.add_dependency(*["mongoid", ">= 3.0", "< 5.0"])

  spec.add_dependency(*["mime-types", ">= 1.0", "< 3.0"])

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/mongoid-grid_fs"
end
