# -*- encoding : utf-8 -*-
require 'pp'
require_relative 'testing'
require_relative '../lib/mongoid-sequence.rb'

Mongoid.configure do |config|
  config.connect_to('mongoid-sequence')
end
