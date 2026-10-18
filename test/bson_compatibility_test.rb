# frozen_string_literal: true

require_relative 'helper'
require 'open3'
require 'rbconfig'

class BsonCompatibilityTest < Minitest::Test
  def test_moped_namespace_without_legacy_binary_uses_modern_bson
    script = <<~RUBY
      require 'logger'
      require 'mongoid'
      Object.const_set(:Moped, Module.new) unless defined?(Moped)
      Moped.const_set(:BSON, Module.new) unless defined?(Moped::BSON)
      require 'mongoid/grid_fs'
      namespace = Mongoid::GridFs.namespace_for(:bsoncompatibility)
      binary = namespace.binary_for("one", "two")
      abort "wrong binary type" unless binary.is_a?(BSON::Binary)
      abort "wrong bytes" unless binary.data == "onetwo"
      abort "wrong field type" unless namespace.chunk_model.fields.fetch("data").type == BSON::Binary
    RUBY

    output, status = Open3.capture2e(RbConfig.ruby, '-Ilib', '-e', script)
    assert status.success?, output
  end
end
