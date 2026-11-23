# frozen_string_literal: true

if RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3') &&
   Gem.loaded_specs.key?('ruby-gem-release')
  require 'minitest/autorun'
  require_relative '../script/release'
  require 'ruby-gem-release/rspec'

  class ReleaseTest < Minitest::Test
    include RubyGemRelease::RSpec

    ROOT = File.expand_path('..', __dir__)
    VERSION_PATH = 'lib/mongoid/grid_fs/version.rb'
    PLACEHOLDER = '* Your contribution here.'
    NOTE = '* [#1](https://github.com/mongoid/mongoid-grid_fs/pull/1): Added a feature.'
    FILES = %w[mongoid-grid_fs.gemspec script/release.rb lib/**/*.rb CHANGELOG.md CONTRIBUTING.md LICENSE README.md].freeze

    def changelog(notes)
      ['### 1.2.0 (Next)', '', notes, PLACEHOLDER, '', '### 1.1.0 (2026/01/01)', '', '* Previous release.', ''].join("\n")
    end

    def with_project(notes)
      with_release_project do |project|
        project.copy_files(path: ROOT, files: FILES)
        project.configure_workflow(require: 'script/release', builder: 'MongoidGridFsRelease.workflow')
        project.write('CHANGELOG.md', changelog(notes))
        source = File.read(File.join(ROOT, VERSION_PATH))
        project.write(VERSION_PATH, source.sub(/VERSION = (['"])[^'"]+\1/, "VERSION = '1.2.0'"))
        project.commit!
        yield project
      end
    end

    def test_builds_the_standard_workflow
      assert_kind_of RubyGemRelease::Workflow::RubyGem, MongoidGridFsRelease.workflow
    end

    def test_dates_the_release_and_prepares_the_next_patch_version
      with_project(NOTE) do |project|
        project.release!

        released = project.remote_file('v1.2.0', 'CHANGELOG.md')
        assert_match(%r{\A### 1\.2\.0 \(\d{4}/\d{2}/\d{2}\)\n\n}, released)
        assert_includes released, NOTE
        refute_includes released, PLACEHOLDER
        assert_includes project.remote_file('v1.2.0', VERSION_PATH), "VERSION = '1.2.0'"
        assert project.remote_file('master', 'CHANGELOG.md').start_with?("### 1.2.1 (Next)\n\n#{PLACEHOLDER}\n\n### 1.2.0 (")
        assert_includes project.remote_file('master', VERSION_PATH), "VERSION = '1.2.1'"
        assert_empty project.git('status', '--porcelain')
      end
    end

    def test_rejects_placeholder_only_notes_without_changing_remote_refs
      with_project('') do |project|
        original = project.git('rev-parse', 'origin/master')
        project.run_task('release:workflow:capture')

        error = assert_raises(RuntimeError) { project.run_task('release:validate') }
        assert_match(/no pending changelog notes/, error.message)
        assert_empty project.git('status', '--porcelain')
        assert_equal original, project.git('rev-parse', 'origin/master')
      end
    end
  end
end
