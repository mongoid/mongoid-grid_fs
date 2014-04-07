mongoid-grid_fs [![Gem Version](https://badge.fury.io/rb/mongoid-grid_fs.svg)](http://badge.fury.io/rb/mongoid-grid_fs) [![Build Status](https://travis-ci.org/ahoward/mongoid-grid_fs.svg)](https://travis-ci.org/ahoward/mongoid-grid_fs)
----

A pure Mongoid/Moped implementation of the MongoDB GridFS specification

INSTALL
-------

```
gem install mongoid-grid_fs
```


SYNOPSIS
--------

```ruby
require 'mongoid/grid_fs'

grid_fs = Mongoid::GridFs
f = grid_fs.put(readable)

grid_fs.get(f.id)
grid_fs.delete(f.id)
```

DESCRIPTION
-----------

mongoid_grid_fs is A pure Mongoid/Moped implementation of the MongoDB GridFS specification

Reference: http://docs.mongodb.org/manual/reference/gridfs/

It has the following features:

- implementation is on top of mongoid for portability.  moped (the driver) is
  barely used, so the library should be quite durable except in the face of
  massive changes to mongoid itself.

- simple, REST-like api

- support for custom namespaces (fs.files vs. image.files, as per the spec)

- pathnames and io-like objects can be written to the grid

- auto-unique pathnames are generated (by default) to avoid collisions using #put

    'path/info/a.rb' -> '$object_id/a.rb'

- [] and []= methods which allow the grid to be used like a giant file
  hash in the sky

- support for data_uris, like a html5 boss

    ```erb
    <%= image_tag :src => file.data_uri %>
    ```

CONTRIBUTING
------------

```
$ bundle install
$ bundle exec rake test
```

LICENSE
-------

This is licensed under the Ruby License: http://www.ruby-lang.org/en/about/license.txt
