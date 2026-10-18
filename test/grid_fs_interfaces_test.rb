# frozen_string_literal: true

require_relative 'helper'

class GridFsInterfacesTest < Minitest::Test
  GridFs = Mongoid::GridFs

  class ReadOnlyStream
    def initialize(data)
      @io = StringIO.new(data)
    end

    def read(size)
      @io.read(size)
    end
  end

  class WholeStream
    def initialize(data)
      @data = data
    end

    def read
      @data
    end
  end

  class FailingStream < StringIO
    def read(size)
      raise IOError, 'interrupted upload' if pos.positive?

      super
    end
  end

  class Renderer
    include Mongoid::GridFsHelper

    attr_accessor :content_type, :response_body
    attr_reader :headers

    def initialize
      @headers = {}
    end
  end

  def setup
    @namespace = GridFs.namespace_for(:interfacetests)
    @namespace.clear
  end

  def teardown
    @namespace.clear
  end

  def test_namespace_identity_models_and_collection_isolation
    assert_same @namespace, GridFs.namespace_for('InterfaceTests')
    assert_equal 'interfacetests', @namespace.to_s
    assert_equal 'interfacetests', @namespace.namespace
    assert_equal 'interfacetests.files', @namespace.file_model.collection_name.to_s
    assert_equal 'interfacetests.chunks', @namespace.chunk_model.collection_name.to_s
    default_count = GridFs.file_model.count

    file = @namespace.put(StringIO.new('isolated'))
    file = @namespace.get(file.id)
    chunk = file.chunks.first

    assert_equal 'isolated', file.data
    assert_same @namespace, file.namespace
    assert_same @namespace, chunk.namespace
    assert_equal 'interfacetests', file.prefix
    assert_equal default_count, GridFs.file_model.count
    assert_equal 'isolated', chunk.to_str
  end

  def test_normalized_upload_attributes_survive_reload
    uploaded_at = Time.utc(2020, 1, 2, 3, 4, 5)
    file = @namespace.put(
      StringIO.new("binary\x00payload".b),
      'filename' => 'nested/payload.bin',
      'content_type' => 'application/custom', 'upload_date' => uploaded_at,
      'meta_data' => { 'source' => 'integration test' },
      'aliases' => [:one, [nil, 'two']]
    )
    file = @namespace.get(file.id)

    assert file.persisted?
    assert_equal 'nested/payload.bin', file.path
    assert_equal 'payload.bin', file.basename
    assert_equal 'payload.bin', file.attachment_filename
    assert_equal 'application/custom', file.content_type
    assert_equal uploaded_at, file.uploadDate
    assert_equal({ 'source' => 'integration test' }, file.metadata)
    assert_equal %w[one two], file.aliases
    assert_equal 14, file.length
    assert_equal Digest::MD5.hexdigest("binary\x00payload".b), file.md5
    assert_equal "binary\x00payload".b, file.data
  end

  def test_base64_and_data_uri_encode_the_stored_bytes
    payload = "binary\x00\xffpayload".b * 12
    file = @namespace.put(StringIO.new(payload), filename: 'encoded.bin', chunk_size: 8)
    file = @namespace.get(file.id)

    assert_equal [payload].pack('m'), file.base64
    assert_equal payload, file.base64.unpack1('m')
    assert_equal "data:application/octet-stream;base64,#{[payload].pack('m').chomp}", file.data_uri
  end

  def test_explicit_gridfs_attributes
    uploaded_at = Time.utc(2021, 2, 3)
    file = @namespace.put(
      StringIO.new('data'), filename: 'data.txt',
                            contentType: 'text/custom', uploadDate: uploaded_at,
                            md5: 'provided-checksum', length: 123
    )
    file.reload

    assert_equal 'text/custom', file.content_type
    assert_equal uploaded_at, file.uploadDate
    assert_equal 'provided-checksum', file.md5
    assert_equal 123, file.length
    assert_equal 'data', file.data
  end

  def test_queries_and_latest_revision
    older = @namespace.put(StringIO.new('old'), filename: 'versions.txt', upload_date: Time.utc(2020))
    newer = @namespace.put(StringIO.new('new'), filename: 'versions.txt', upload_date: Time.utc(2021))

    assert_equal [older.id, newer.id].sort, @namespace.where('versions.txt').map(&:id).sort
    assert_equal newer.id, @namespace.where(md5: newer.md5).first.id
    assert_equal older.id, @namespace.find(id: older.id).id
    assert_equal newer.id, @namespace['versions.txt'].id
    assert_nil @namespace.find('missing.txt')
    assert_nil @namespace['missing.txt']
    assert_nil @namespace.delete(@namespace.file_model.new.id)
  end

  def test_default_namespace_delegation_and_cascading_clear
    file = GridFs.put(StringIO.new('default namespace'), filename: 'coverage-default.txt')
    assert_equal file.id, GridFs.find(filename: file.filename).id
    chunk_ids = file.chunks.map(&:id)

    GridFs.delete(file.id)

    assert_empty GridFs.chunk_model.where(:id.in => chunk_ids).to_a
    assert_raises(Mongoid::Errors::DocumentNotFound) { GridFs.get(file.id) }

    file = @namespace.put(StringIO.new('clear namespace'))
    @namespace.clear
    assert_equal 0, @namespace.file_model.count
    assert_equal 0, @namespace.chunk_model.count
    assert_raises(Mongoid::Errors::DocumentNotFound) { @namespace.get(file.id) }
  end

  def test_streaming_and_slicing_across_more_than_one_fetch_batch
    data = "#{'abcdefgh' * GridFs::File.defaults.chunkSize}end"
    file = @namespace.put(StringIO.new(data))
    file = @namespace.get(file.id)
    chunks = []

    file.each { |chunk| chunks << chunk }

    assert_equal 9, file.chunks.count
    assert_equal data, chunks.join
    assert_equal data.bytesize, file.length
    assert_equal Digest::MD5.hexdigest(data), file.md5
    boundary = file.chunkSize - 2
    assert_equal data[boundary, 10], file.slice(boundary, 10)
    assert_equal data[boundary..(boundary + 10)], file.slice(boundary..(boundary + 10))
    assert_equal data[boundary...(boundary + 10)], file.slice(boundary...(boundary + 10))
    assert_equal data[-10, 10], file.slice(-10, 10)
    assert_equal data[-1], file.slice(-1)
  end

  def test_response_body_and_byte_interfaces
    file = @namespace.put(StringIO.new('response body'), filename: 'response.txt')
    file.reload
    yielded = []

    assert_equal file.length, (file.bytes { |chunk| yielded << chunk })
    assert_equal ['response body'], yielded
    assert_equal yielded, file.bytes
    assert_same file, file.close
  end

  def test_empty_upload
    file = @namespace.put(StringIO.new(''))
    file.reload

    assert_equal 0, file.length
    assert_equal Digest::MD5.hexdigest(''), file.md5
    assert_equal 0, file.chunks.count
    assert_equal '', file.data
    assert_equal [], file.bytes
    yielded = []
    assert_equal 0, (file.bytes { |chunk| yielded << chunk })
    assert_empty yielded
  end

  def test_nonseekable_stream_and_no_argument_read_adapter
    file = @namespace.put(ReadOnlyStream.new('nonseekable'))
    assert_equal 'nonseekable', @namespace.get(file.id).data

    data = 'whole stream' * 400_000
    file = @namespace.put(WholeStream.new(data))
    assert_equal 2, file.chunks.count
    assert_equal data, @namespace.get(file.id).data
    assert_equal Digest::MD5.hexdigest(data), file.reload.md5

    file = @namespace.put(WholeStream.new(''))
    assert_equal '', @namespace.get(file.id).data
    assert_equal 0, file.chunks.count
  end

  def test_upload_rewinds_and_restores_position_without_closing_caller_io
    io = StringIO.new('complete payload')
    io.pos = 4
    file = @namespace.put(io)

    assert_equal 'complete payload', @namespace.get(file.id).data
    assert_equal 4, io.pos
    refute io.closed?
  end

  def test_failed_stream_upload_removes_persisted_file_and_chunks_and_restores_io
    io = FailingStream.new('x' * (GridFs::File.defaults.chunkSize + 1))
    io.pos = 3
    error = assert_raises(IOError) { @namespace.put(io) }

    assert_equal 'interrupted upload', error.message
    assert_equal 3, io.pos
    refute io.closed?
    assert_equal 0, @namespace.file_model.count
    assert_equal 0, @namespace.chunk_model.count
  end

  def test_chunking_no_argument_reader_preserves_final_partial_chunk
    chunks = []
    GridFs.chunking(WholeStream.new('abcdefghij'), 4) { |chunk| chunks << chunk }
    assert_equal %w[abcd efgh ij], chunks
  end

  def test_attachment_name_for_explicit_paths_without_a_stored_filename
    file = @namespace.put(StringIO.new('attachment'), filename: nil, content_type: 'text/plain')
    file.reload

    assert_nil file.basename
    assert_equal 'report--final.txt', file.attachment_filename('report', 'final.pdf')
  end

  def test_historical_file_without_filename_or_update_date
    id = @namespace.file_model.new.id
    uploaded_at = Time.utc(2013, 4, 7)
    document = {
      _id: id, length: 0, chunkSize: 262_144, uploadDate: uploaded_at,
      md5: Digest::MD5.hexdigest(''), contentType: 'text/plain'
    }
    collection = @namespace.file_model.collection
    collection.respond_to?(:insert_one) ? collection.insert_one(document) : collection.insert(document)
    file = @namespace.get(id)

    assert_equal uploaded_at, file.uploadDate
    refute file.attributes.key?('updateDate')
    assert_nil file.basename
    assert_equal '', file.data
    assert_equal 'download.txt', file.attachment_filename('download')

    # Historical GridFS records have uploadDate, not the updateDate these APIs read.
    %i[attachment_filename update_date created_at].each do |method|
      error = assert_raises(NameError) { file.public_send(method) }
      assert_equal :updateDate, error.name
    end
  end

  def test_unimplemented_open_is_explicit
    assert_raises(NotImplementedError) { @namespace.open('file.txt') }
    assert_raises(NotImplementedError) { @namespace.open('file.txt', 'w') }
  end

  def test_defaults_support_attribute_access_and_reject_unknown_keys
    defaults = GridFs::Defaults.new
    defaults.chunkSize = 1024

    assert_equal 1024, defaults.chunkSize
    assert_equal 1024, defaults['chunkSize']
    assert_raises(NoMethodError) { defaults.unknown_setting }
  end

  def test_content_type_detection_and_default_options
    assert_equal 'text/x-markdown; charset=UTF-8', GridFs.extract_content_type('README.md')
    assert_equal 'text/plain', GridFs.extract_content_type('dir/file.txt')
    assert_nil GridFs.extract_content_type('unknown.not-a-real-extension', default: false)
    assert_equal 'application/octet-stream', GridFs.extract_content_type('unknown', default: true)
    assert_equal 'application/custom', GridFs.extract_content_type('unknown', 'default' => 'application/custom')
    assert_equal 'txt', GridFs.extract_extension('text/plain')
    assert_nil GridFs.extract_extension('application/not-a-real-content-type')
  end

  def test_uploaded_filename_is_cleaned
    io = SIO.new('/uploads/a%20b+%26%26.txt', 'payload')
    file = @namespace.put(io)
    assert_equal "#{file.id}/a_b_.txt", file.reload.filename
    assert_equal 'text/plain', file.content_type
  end

  def test_rails_helper_streams_inline_and_attachment_responses
    file = @namespace.put(StringIO.new('rendered'), filename: 'rendered.txt')
    [nil, { inline: false }, { 'attachment' => true }].each do |options|
      renderer = Renderer.new
      renderer.grid_fs_render(file, options || {})

      assert_equal file.content_type, renderer.content_type
      assert_same file, renderer.response_body
      chunks = []
      renderer.response_body.each { |chunk| chunks << chunk }
      assert_equal 'rendered', chunks.join
      if options
        assert_equal 'attachment; filename=rendered.txt', renderer.headers['Content-Disposition']
      else
        assert_empty renderer.headers
      end
    end
  end

  def test_public_require_paths
    require 'mongoid-grid_fs'
    require 'mongoid/grid_fs/version'
    require_relative '../lib/app/models/mongoid/grid_fs'
    require_relative '../lib/app/models/mongoid/grid_fs/fs/file'
    require_relative '../lib/app/models/mongoid/grid_fs/fs/chunk'

    assert_match(/\A\d+\.\d+\.\d+\z/, Mongoid::GridFs::VERSION)
    assert_same GridFs, Mongoid::GridFS
    assert_same GridFs::Fs::File, GridFs::File
    assert_same GridFs::Fs::Chunk, GridFs::Chunk
  end
end
