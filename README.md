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

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [CHANGELOG.md](CHANGELOG.md).

## License

Licensed under the [Ruby License](https://www.ruby-lang.org/en/about/license.txt), see [LICENSE](LICENSE).
