mongoid-grid_fs
---------------

[![Gem Version](https://badge.fury.io/rb/mongoid-grid_fs.svg)](https://badge.fury.io/rb/mongoid-grid_fs)
[![CI](https://github.com/mongoid/mongoid-grid_fs/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/mongoid/mongoid-grid_fs/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/mongoid/mongoid-grid_fs/badge.svg?branch=master)](https://coveralls.io/github/mongoid/mongoid-grid_fs?branch=master)

A pure Mongoid/Moped implementation of the MongoDB GridFS specification

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

g = grid_fs.get(f.id)
g.data # big huge blob
g.each { |chunk| file.write(chunk) } # streaming write

```

QUERYING AND STORAGE
--------------------

`where` returns chainable Mongoid criteria for multiple files, while `find` returns the first match:

```ruby
Mongoid::GridFs.where(filename: 'report.pdf').each { |file| puts file.id }
Mongoid::GridFs.where(contentType: 'application/pdf').limit(10)
```

To use `attachments.files` and `attachments.chunks` instead of `fs.files` and `fs.chunks`, use a named namespace for all operations:

```ruby
attachments = Mongoid::GridFs.namespace_for(:attachments)
file = attachments.put(readable, filename: 'report.pdf')
attachments.where(filename: 'report.pdf')
attachments.get(file.id)
attachments.delete(file.id)
```

For a separate host on Mongoid 5+, configure a named Mongoid client (for example `gridfs`) in `mongoid.yml`, then select it on both models during application initialization, before any GridFS operations:

```ruby
attachments.file_model.store_in client: :gridfs
attachments.chunk_model.store_in client: :gridfs
```

The named client supplies the hosts, database, and credentials through normal Mongoid configuration. To change only the database, use `store_in database: 'attachments_database'` on both models instead. Keep files and chunks on the same client and database. These settings are shared model configuration, not per-request switches. Mongoid 3/4 use named sessions and `store_in session: :gridfs` instead of clients.

Use `file.destroy`, `grid_fs.delete(id)`, or `namespace.clear` to remove files and associated chunks. Mongoid's callback-skipping operations such as `file.delete`, `delete_all`, and direct collection deletes do not perform dependent destruction and can leave orphaned chunks.

CONTRIBUTING
------------

See [CONTRIBUTING](CONTRIBUTING.md).

LICENSE
-------

This is licensed under the Ruby License: http://www.ruby-lang.org/en/about/license.txt
