require 'bundler/gem_tasks'

if RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3') &&
   Gem.loaded_specs.key?('ruby-gem-release')
  require_relative 'script/release'
  MongoidGridFsRelease.workflow.install_tasks

  %w[release release:rubygem_push release:source_control_push].each do |name|
    Rake::Task[name].clear
    desc 'Disabled; releases run through GitHub Actions, see RELEASING.md'
    task(name) { abort "#{name} is disabled; releases run through GitHub Actions, see RELEASING.md" }
  end
end
require 'bundler/setup'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

lint = RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3') &&
       Gem.loaded_specs.key?('rubocop')
if lint
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop)

  desc 'Lint Ruby, Markdown, YAML, and spelling'
  task lint: :rubocop
end

task default: lint ? %i[rubocop test] : %i[test]
