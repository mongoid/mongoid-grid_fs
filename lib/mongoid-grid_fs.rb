##
#
  module Mongoid
    class GridFS
      const_set :Version, '1.9.0'

      class << GridFS
        def version
          const_get :Version
        end

        def dependencies
          {
            'mongoid'         => [ 'mongoid'         , '~> 3.0' ] ,
            'mime/types'      => [ 'mime-types'      , '~> 1.19'] ,
          }
        end

        def libdir(*args, &block)
          @libdir ||= File.expand_path(__FILE__).sub(/\.rb$/,'')
          args.empty? ? @libdir : File.join(@libdir, *args)
        ensure
          if block
            begin
              $LOAD_PATH.unshift(@libdir)
              block.call()
            ensure
              $LOAD_PATH.shift()
            end
          end
        end

        def load(*libs)
          libs = libs.join(' ').scan(/[^\s+]+/)
          libdir{ libs.each{|lib| Kernel.load(lib) } }
        end
      end

      begin
        require 'rubygems'
      rescue LoadError
        nil
      end

      if defined?(gem)
        dependencies.each do |lib, dependency|
          gem(*dependency)
          require(lib)
        end
      end

      require "digest/md5"
      require "cgi"
    end
  end

##
#
  module Mongoid
    class GridFS
      class << GridFS
        attr_accessor :namespace
        attr_accessor :file_model
        attr_accessor :chunk_model

        def init!
          GridFS.build_namespace_for(:Fs)

          GridFS.namespace = Fs
          GridFS.file_model = Fs.file_model
          GridFS.chunk_model = Fs.chunk_model

          const_set(:File, Fs.file_model)
          const_set(:Chunk, Fs.chunk_model)

          to_delegate = %w(
            put
            get
            delete
            find
            []
            []=
            clear
          )
          
          to_delegate.each do |method|
            class_eval <<-__
              def self.#{ method }(*args, &block)
                ::Mongoid::GridFS::Fs::#{ method }(*args, &block)
              end
            __
          end
        end
      end

    ##
    #
      def GridFS.namespace_for(prefix)
        prefix = prefix.to_s.downcase
        const = "::GridFS::#{ prefix.to_s.camelize }"
        namespace = const.split(/::/).last
        const_defined?(namespace) ? const_get(namespace) : build_namespace_for(namespace)
      end

    ##
    #
      def GridFS.build_namespace_for(prefix)
        prefix = prefix.to_s.downcase
        const = prefix.camelize

        namespace =
          Module.new do
            module_eval(&NamespaceMixin)
            self
          end

        const_set(const, namespace)

        file_model = build_file_model_for(namespace)
        chunk_model = build_chunk_model_for(namespace)

        file_model.namespace = namespace
        chunk_model.namespace = namespace

        file_model.chunk_model = chunk_model
        chunk_model.file_model = file_model

        namespace.prefix = prefix
        namespace.file_model = file_model
        namespace.chunk_model = chunk_model

        namespace.send(:const_set, :File, file_model)
        namespace.send(:const_set, :Chunk, chunk_model)

        #at_exit{ file_model.create_indexes rescue nil }
        #at_exit{ chunk_model.create_indexes rescue nil }

        const_get(const)
      end

      NamespaceMixin = proc do
        class << self
          attr_accessor :prefix
          attr_accessor :file_model
          attr_accessor :chunk_model

          def to_s
            prefix
          end

          def namespace
            prefix
          end

          def put(readable, attributes = {})
            chunks = []
            file = file_model.new
            attributes.to_options!

            if attributes.has_key?(:id)
              file.id = attributes.delete(:id)
            end

            if attributes.has_key?(:_id)
              file.id = attributes.delete(:_id)
            end

            if attributes.has_key?(:content_type)
              attributes[:contentType] = attributes.delete(:content_type)
            end

            if attributes.has_key?(:upload_date)
              attributes[:uploadDate] = attributes.delete(:upload_date)
            end

            md5 = Digest::MD5.new
            length = 0
            chunkSize = file.chunkSize
            n = 0

            GridFS.reading(readable) do |io|

              filename =
                attributes[:filename] ||=
                  [file.id.to_s, GridFS.extract_basename(io)].join('/').squeeze('/')

              content_type =
                attributes[:contentType] ||=
                  GridFS.extract_content_type(filename) || file.contentType

              GridFS.chunking(io, chunkSize) do |buf|
                md5 << buf
                length += buf.size
                chunk = file.chunks.build
                chunk.data = binary_for(buf)
                chunk.n = n
                n += 1
                chunk.save!
                chunks.push(chunk)
              end

            end

            attributes[:length] ||= length
            attributes[:uploadDate] ||= Time.now.utc
            attributes[:md5] ||= md5.hexdigest

            file.update_attributes(attributes)

            file.save!
            file
          rescue
            chunks.each{|chunk| chunk.destroy rescue nil}
            raise
          end

          if defined?(Moped)
            def binary_for(*buf)
              Moped::BSON::Binary.new(:generic, buf.join)
            end
          else
            def binary_for(buf)
              BSON::Binary.new(buf.bytes.to_a)
            end
          end

          def get(id)
            file_model.find(id)
          end

          def delete(id)
            file_model.find(id).destroy
          rescue
            nil
          end

          def where(conditions = {})
            case conditions
              when String
                file_model.where(:filename => conditions)
              else
                file_model.where(conditions)
            end
          end

          def find(*args)
            where(*args).first
          end

          def [](filename)
            file_model.where(:filename => filename.to_s).first
          end

          def []=(filename, readable)
            file = self[filename]
            file.destroy if file
            put(readable, :filename => filename.to_s)
          end

          def clear
            file_model.destroy_all
          end

        # TODO - opening with a mode = 'w' should return a GridIO::IOProxy
        # implementing a StringIO-like interface
        #
          def open(filename, mode = 'r', &block)
            raise NotImplementedError
          end
        end
      end

    ##
    #
      class Defaults < ::Hash
        def method_missing(method, *args, &block)
          case method.to_s
            when /(.*)=/
              key = $1
              val = args.first
              update(key => val)
            else
              key = method.to_s
              super unless has_key?(key)
              fetch(key)
          end
        end
      end

    ##
    #
      def GridFS.build_file_model_for(namespace)
        prefix = namespace.name.split(/::/).last.downcase
        file_model_name = "#{ namespace.name }::File"
        chunk_model_name = "#{ namespace.name }::Chunk"

        Class.new do
          include Mongoid::Document

          singleton_class = class << self; self; end

          singleton_class.instance_eval do
            define_method(:name){ file_model_name }
            attr_accessor :namespace
            attr_accessor :chunk_model
            attr_accessor :defaults
          end

          self.default_collection_name = "#{ prefix }.files"
          self.defaults = Defaults.new

          self.defaults.chunkSize = 4 * (mb = 2**20)
          self.defaults.contentType = 'application/octet-stream'

          field(:filename, :type => String)
          field(:contentType, :type => String, :default => defaults.contentType)

          field(:length, :type => Integer, :default => 0)
          field(:chunkSize, :type => Integer, :default => defaults.chunkSize)
          field(:uploadDate, :type => Date, :default => Time.now.utc)
          field(:md5, :type => String, :default => Digest::MD5.hexdigest(''))

          %w( filename contentType length chunkSize uploadDate md5 ).each do |f|
            validates_presence_of(f)
          end
          validates_uniqueness_of(:filename)

          has_many(:chunks, :class_name => chunk_model_name, :inverse_of => :files, :dependent => :destroy, :order => [:n, :asc])

          index({:filename => 1}, :unique => true) 

          def path
            filename
          end

          def basename
            ::File.basename(filename)
          end

          def prefix
            self.class.namespace.prefix
          end

          def each(&block)
            chunks.all.order_by([:n, :asc]).each do |chunk|
              block.call(chunk.to_s)
            end
          end

          def slice(*args)
            case args.first
              when Range
                range = args.first
                first_chunk = (range.min / chunkSize).floor
                last_chunk = (range.max / chunkSize).ceil
                offset = range.min % chunkSize
                length = range.max - range.min + 1
              when Fixnum
                start = args.first
                start = self.length + start if start < 0
                length = args.size == 2 ? args.last : 1
                first_chunk = (start / chunkSize).floor
                last_chunk = ((start + length) / chunkSize).ceil
                offset = start % chunkSize
            end

            data = ''

            chunks.where(:n => (first_chunk..last_chunk)).order_by(n: 'asc').each do |chunk|
              data << chunk
            end

            data[offset, length]
          end

          def data
            data = ''
            each{|chunk| data << chunk}
            data
          end

          def base64
            Array(to_s).pack('m')
          end

          def data_uri(options = {})
            data = base64.chomp
            "data:#{ content_type };base64,".concat(data)
          end

          def bytes(&block)
            if block
              each{|data| block.call(data)}
              length
            else
              bytes = []
              each{|data| bytes.push(*data)}
              bytes
            end
          end

          def close
            self
          end

          def content_type
            contentType
          end

          def update_date 
            updateDate
          end

          def created_at
            updateDate
          end

          def namespace
            self.class.namespace
          end
        end
      end

    ##
    #
      def GridFS.build_chunk_model_for(namespace)
        prefix = namespace.name.split(/::/).last.downcase
        file_model_name = "#{ namespace.name }::File"
        chunk_model_name = "#{ namespace.name }::Chunk"

        Class.new do
          include Mongoid::Document

          singleton_class = class << self; self; end

          singleton_class.instance_eval do
            define_method(:name){ chunk_model_name }
            attr_accessor :file_model
            attr_accessor :namespace
          end

          self.default_collection_name = "#{ prefix }.chunks"

          field(:n, :type => Integer, :default => 0)
          field(:data, :type => (defined?(Moped) ? Moped::BSON::Binary : BSON::Binary))

          belongs_to(:file, :foreign_key => :files_id, :class_name => file_model_name)

          index({:files_id => 1, :n => -1}, :unique => true) 

          def namespace
            self.class.namespace
          end

          def to_s
            data.data
          end

          alias_method 'to_str', 'to_s'
        end
      end

    ##
    #
      def GridFS.reading(arg, &block)
        if arg.respond_to?(:read)
          rewind(arg) do |io|
            block.call(io)
          end
        else
          open(arg.to_s) do |io|
            block.call(io)
          end
        end
      end

      def GridFS.chunking(io, chunk_size, &block)
        if io.method(:read).arity == 0
          data = io.read
          i = 0
          loop do
            offset = i * chunk_size
            length = i + chunk_size < data.size ? chunk_size : data.size - offset

            break if offset >= data.size

            buf = data[offset, length]
            block.call(buf)
            i += 1
          end
        else
          while((buf = io.read(chunk_size)))
            block.call(buf)
          end
        end
      end

      def GridFS.rewind(io, &block)
        begin
          pos = io.pos
          io.flush
          io.rewind
        rescue
          nil
        end

        begin
          block.call(io)
        ensure
          begin
            io.pos = pos
          rescue
            nil
          end
        end
      end

      def GridFS.extract_basename(object)
        filename = nil

        [:original_path, :original_filename, :path, :filename, :pathname].each do |msg|
          if object.respond_to?(msg)
            filename = object.send(msg)
            break
          end
        end

        filename ? cleanname(filename) : nil
      end

      MIME_TYPES = {
        'md' => 'text/x-markdown; charset=UTF-8'
      }

      def GridFS.mime_types
        MIME_TYPES
      end

      def GridFS.extract_content_type(filename, options = {})
        options.to_options!

        basename = ::File.basename(filename.to_s)
        parts = basename.split('.')
        parts.shift
        ext = parts.pop

        default =
          case
            when options[:default]==false
              nil
            when options[:default]==true
              "application/octet-stream"
            else
              (options[:default] || "application/octet-stream").to_s
          end

        content_type = mime_types[ext] || MIME::Types.type_for(::File.basename(filename.to_s)).first

        if content_type
          content_type.to_s
        else
          default
        end
      end

      def GridFS.cleanname(pathname)
        basename = ::File.basename(pathname.to_s)
        CGI.unescape(basename).gsub(%r/[^0-9a-zA-Z_@)(~.-]/, '_').gsub(%r/_+/,'_')
      end
    end

    GridFs = GridFS
    GridFS.init!
  end

##
#
  if defined?(Rails)
    class Mongoid::GridFS::Engine < Rails::Engine
      paths['app/models'] = File.dirname(__FILE__)
    end

    module Mongoid::GridFSHelper
      def grid_fs_render(grid_fs_file, options = {})
        options.to_options!

        if options[:inline] == false or options[:attachment] == true
          headers['Content-Disposition'] = "attachment; filename=#{ grid_fs_file.filename }"
        end

        self.content_type = grid_fs_file.content_type
        self.response_body = grid_fs_file
      end
    end

    Mongoid::GridFS::Helper = Mongoid::GridFSHelper
  end
