# Mongoid::GridFs

[![Gem Version](https://badge.fury.io/rb/mongoid-grid_fs.svg)](https://badge.fury.io/rb/mongoid-grid_fs) [![CI](https://github.com/mongoid/mongoid-grid_fs/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/mongoid/mongoid-grid_fs/actions/workflows/ci.yml) [![Lint](https://github.com/mongoid/mongoid-grid_fs/actions/workflows/lint.yml/badge.svg?branch=master)](https://github.com/mongoid/mongoid-grid_fs/actions/workflows/lint.yml) [![Coverage Status](https://coveralls.io/repos/github/mongoid/mongoid-grid_fs/badge.svg?branch=master)](https://coveralls.io/github/mongoid/mongoid-grid_fs?branch=master)

A pure Mongoid implementation of the [MongoDB GridFS specification](https://www.mongodb.com/docs/manual/core/gridfs/).

## Installation

Add the gem to your Gemfile and run `bundle install`.

```ruby
gem 'mongoid-grid_fs'
```

## Usage

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

## Features

- Implemented on top of Mongoid for portability, using the driver as little as possible.
- A simple, REST-like API.
- Custom namespaces, such as `fs.files` or `image.files`, as the specification allows.
- Pathnames and IO-like objects can be written to the grid.
- `put` generates unique pathnames by default to avoid collisions, for example `path/info/a.rb` becomes `$object_id/a.rb`.
- `[]` and `[]=` let you use the grid like a giant file hash.
- Data URIs, for example `image_tag file.data_uri`.

## Querying and Storage

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

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [CHANGELOG.md](CHANGELOG.md).

## License

Licensed under the [Ruby License](https://www.ruby-lang.org/en/about/license.txt), see [LICENSE](LICENSE).
