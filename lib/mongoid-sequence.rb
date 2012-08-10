require 'mongoid'

module Mongoid
  module Sequence
    def Sequence.version
      '1.0.0'
    end

    ClassMethods = proc do
      def sequence(fieldname, *args, &block)
        options = args.extract_options!.to_options!

        sequence_name = (
          options.delete(:sequence) || sequence_name_for(fieldname)
        )

        args.push(options)

        before_create do |doc|
          doc[fieldname] = SequenceGenerator.for(sequence_name).next
        end

        field(fieldname, *args, &block)

        SequenceGenerator.for(sequence_name)
      end

      def sequence_for(fieldname)
        SequenceGenerator.for(sequence_name_for(fieldname))
      end

      def sequence_name_for(fieldname)
        SequenceGenerator.sequence_name_for(self, fieldname)
      end
    end

    InstanceMethods = proc do
      def sequence_for(fieldname)
        self.class.sequence_for(fieldname)
      end
    end

    def Sequence.included(other)
      other.send(:instance_eval, &ClassMethods)
      other.send(:class_eval, &InstanceMethods)
      super
    end
  end

  class SequenceGenerator
    include Mongoid::Document

    field(:name, :type => String)

    field(:value, :default => 0, :type => Integer)

    validates_presence_of(:name)
    validates_uniqueness_of(:name)

    validates_presence_of(:value)

    index({:name => 1}, {:unique => true})

    Cache = Hash.new

    class << self
      def for(name)
        name = name.to_s

        Cache[name] ||= (
          begin
            create!(:name => name)
          rescue
            where(:name => name).first || create!(:name => name)
          end
        )
      end

      alias_method('[]', 'for')

      def sequence_name_for(klass, fieldname)
        "#{ klass.name.underscore }-#{ fieldname }"
      end
    end

    after_destroy do |sequence|
      Cache.delete(sequence.name)
    end

    def next
      inc(:value, 1)
    end

    def current_value
      reload.value
    end

    def reset!
      update_attributes!(:value => 0)
    end
  end
end




if $0 == __FILE__

  Mongoid.configure do |config|
    config.connect_to('mongoid-sequence')
  end

  class A
    include Mongoid::Document
    include Mongoid::Sequence

    p sequence(:number)
  end

  A.sequence_for(:number).destroy
  
  a = A.create!
  p a

end
