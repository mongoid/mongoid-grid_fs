require_relative 'helper'

Testing Mongoid::GridFs do
##
#
  GridFs = Mongoid::GridFs

  prepare do
    GridFs::File.delete_all
    GridFs::Chunk.delete_all
  end

##
#
  context '#put' do

    test 'default' do
      filename = __FILE__
      basename = File.basename(filename)

      g = assert{ GridFs.put(filename) }

      assert{ g.filename =~ %r| #{ object_id_re } / #{ basename } \Z|imox }
      assert{ g.content_type == "application/x-ruby" }
      assert{ g.data == IO.read(filename) }
    end

    test 'with a :filename' do
      filename = 'path/info/a.rb'

      g = assert{ GridFs.put(__FILE__, :filename => filename) }

      assert{ g.filename == filename }
    end

    test 'with your own attributes' do
      my_value = "my_value"

      g = assert{ GridFs.put(__FILE__, :my_value => my_value) }

      assert{ g.my_value == my_value }
    end

    test 'when error occurs (eg. missing file)' do
      file = '/path/to/missing'

      assert_raises(Errno::ENOENT){ GridFs.put(file) }
    end

  end


##
#
  context '#get' do

    test 'default' do
      id = assert{ GridFs::File.last.id }
      g = assert{ GridFs.get(id) }
    end

  end

##
#
  context '#delete' do

    test 'default' do
      id = assert{ GridFs::File.last.id }
      g = assert{ GridFs.get(id) }
      assert{ GridFs.delete(id) }
      assert_raises(Mongoid::Errors::DocumentNotFound){ GridFs.get(id) }
    end

  end

##
#
  context '[] and []=' do

    test 'default' do
      path = 'a.rb'
      data = IO.read(__FILE__)

      sio = SIO.new(path, data)

      g = assert{ GridFs[path] = sio and GridFs[path] }

      assert{ g.data == data }
      assert{ g.content_type == "application/x-ruby" }

      before = GridFs::File.count

      data = "#{ Time.now.to_f }-#{ rand }"

      assert{ GridFs[path] = SIO.new(path, data) }
      assert{ GridFs[path].data == data }

      after = GridFs::File.count

      created = after - before

      assert{ created == 1 }
    end

##
#
  context 'data uris' do

    test 'default' do
      id = assert{ GridFs::File.last.id }
      g = assert{ GridFs.get(id) }

      content_type = g.content_type
      base64 = [g.to_s].pack('m').chomp

      data_uri = "data:#{ content_type };base64,".concat(base64)

      assert{ g.data_uri == data_uri }
    end

  end

##
#
  context 'slicing and dicing' do

    test 'range' do
      id = assert { GridFs::File.last.id }
      g = assert { GridFs.get(id) }
      assert { g.data[1..3] == g.slice(1..3) }
    end

    test 'start and length' do
      id = assert { GridFs::File.last.id }
      g = assert { GridFs.get(id) }
      assert { g.data[1, 3] == g.slice(1, 3) }
    end

    test 'just a single param' do
      id = assert { GridFs::File.last.id }
      g = assert {GridFs.get(id) }

      assert {g.data[1] == g.slice(1) }
    end

    test 'getting the last index' do
      id = assert { GridFs::File.last.id }
      g = assert {GridFs.get(id) }
      assert {g.data[-1] == g.slice(-1) }
    end

    test 'yanking from the end of the data' do
      id = assert { GridFs::File.last.id }
      g = assert {GridFs.get(id) }
      assert {g.data[-3, 2] == g.slice(-3, 2) }
    end

    test 'multiple chunks...' do
      path = 'slice_and_dice.txt'

      assert { GridFs[path] = SIO.new(path, "foobar" * 256 * 1024) }

      g = GridFs[path]

      assert { g.chunks.count > 0 }
      assert { g.data[10, (256 * 1024 * 2)] == g.slice(10, (256 * 1024 * 2)) }
    end
  end

##
#
  context 'iterating each chunk' do
    test 'having file size more than 42mb' do
      require 'tempfile'

      orig, copy = %w{orig copy}.map do |suffix|
        Tempfile.new("mongoid-grid_fs~43mb.#{suffix}")
      end

      kilobyte = "x" * 1024
      (43*1024).times { orig.write(kilobyte) }

      GridFs.get(GridFs.put(orig.path).id).each do |chunk|
        copy.print(chunk.to_s)
      end

      assert { File.size(orig.path) == File.size(copy.path) }
    end
  end

##
#
  context 'namespaces' do
    test 'default' do
      assert{ GridFs.namespace.prefix == 'fs' }
      assert{ GridFs.file_model.collection_name.to_s == 'fs.files' }
      assert{ GridFs.chunk_model.collection_name.to_s == 'fs.chunks' }
    end

    test 'new' do
      ns = GridFs.namespace_for(:ns)

      assert{ ns.prefix == 'ns' }

      assert{ ns.file_model < Mongoid::Document }
      assert{ ns.file_model.collection_name.to_s == 'ns.files' }

      assert{ ns.chunk_model < Mongoid::Document }
      assert{ ns.chunk_model.collection_name.to_s == 'ns.chunks' }

      assert{ ns.file_model.destroy_all }

      count = GridFs::File.count

      assert{ ns.file_model.count == 0}
      assert{ ns.put __FILE__ }
      assert{ ns.file_model.count == 1}

      assert{ count == GridFs::File.count }
    end
  end

  end

##
#
  context 'rails' do
    test 'paths' do
      testdir = File.dirname(__FILE__)
      gemdir = File.dirname(testdir)
      libdir = File.join(gemdir, 'lib')

      expanded = proc{|paths| Array(paths).map{|path| File.expand_path(path)}}

      assert{
        expanded[ Mongoid::GridFs::Engine.paths['app/models'] ] == expanded[ libdir ]
      }
    end
  end

protected
  def object_id_re
    object_id = defined?(Moped::BSON) ? Moped::BSON::ObjectId.new : BSON::ObjectId.new

    %r| \w{#{ object_id.to_s.size }} |iomx
  end
end
