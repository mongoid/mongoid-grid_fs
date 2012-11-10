# -*- encoding : utf-8 -*-

require 'stringio'

class SIO < StringIO
  attr_accessor :filename

  def initialize(filename, *args, &block)
    @filename = filename
    super(*args, &block)
  end
end

# this triggers mongoid to load rails...
module Rails; end

require_relative 'testing'
require_relative '../lib/mongoid-grid_fs.rb'

Mongoid.configure do |config|
  config.connect_to('mongoid-grid_fs_test')
end


