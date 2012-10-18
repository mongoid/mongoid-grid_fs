module Mongoid
  class GridFS
    class Railtie < ::Rails::Railtie
      rake_tasks do
        task 'db:mongoid:create_indexes' do
          ::Mongoid::GridFS::Fs::File.create_indexes
          ::Mongoid::GridFS::Fs::Chunk.create_indexes
        end

        task 'db:mongoid:remove_indexes' do
          ::Mongoid::GridFS::Fs::File.remove_indexes
          ::Mongoid::GridFS::Fs::Chunk.remove_indexes
        end
      end
    end
  end
end

