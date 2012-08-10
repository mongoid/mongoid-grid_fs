NAME
----
  mongoid-sequence

INSTALL
-------
  gem install mongoid-sequence

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
