NAME
----
  mongoid-sequence
  mongoid-grid_fs

INSTALL
-------
  gem install mongoid-sequence
  gem install mongoid-grid_fs

SYNOPSIS
--------

````ruby

  require 'mongoid'
  require 'mongoid-sequence'


  class Page
    include Mongoid::Document
    include Mongoid::Sequence

    sequence :number
  end

  p Page.create.number #=> 1
  p Page.create.number #=> 2
  p Page.create.number #=> 3


````

DESCRIPTION
-----------
mongoid_sequence is a pure mongoid sequence generator based on mongodb's
increment operator

GRIDFS
------
Be sure to create indexes for the GridFS collections with `rake db:mongoid:create_indexes`.

