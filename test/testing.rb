# -*- encoding : utf-8 -*-

require 'minitest/autorun'

testdir = File.expand_path(File.dirname(__FILE__))
rootdir = File.dirname(testdir)
libdir = File.join(rootdir, 'lib')

STDOUT.sync = true

$LOAD_PATH.unshift(testdir) unless $LOAD_PATH.include?(testdir)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
$LOAD_PATH.unshift(rootdir) unless $LOAD_PATH.include?(rootdir)

class Testing
  class Slug < ::String
    def self.for(*args)
      string = args.flatten.compact.join('-')
      words = string.to_s.scan(/\w+/)
      words.map! { |word| word.gsub(/[^0-9a-zA-Z_-]/, '') }
      words.delete_if { |word| word.nil? || word.strip.empty? }
      new(words.join('-').downcase)
    end
  end

  class Context
    attr_accessor :name

    def initialize(name, *_args)
      @name = name
    end

    def to_s
      Slug.for(name)
    end
  end
end

def Testing(*args, &block) # rubocop:disable Naming/MethodName
  Class.new(::Minitest::Test) do
    i_suck_and_my_tests_are_order_dependent!

    ## class methods
    #
    class << self
      def contexts
        @contexts ||= []
      end

      def context(*args, &block)
        return contexts.last if args.empty? && block.nil?

        context = Testing::Context.new(*args)
        contexts.push(context)

        begin
          yield(context)
        ensure
          contexts.pop
        end
      end

      def slug_for(*args)
        string = [context, args].flatten.compact.join('-')
        words = string.to_s.scan(/\w+/)
        words.map! { |word| word.gsub(/[^0-9a-zA-Z_-]/, '') }
        words.delete_if { |word| word.nil? || word.strip.empty? }
        words.join('-').downcase.sub(/_$/, '')
      end

      def name
        const_get(:Name)
      end

      def testno
        '%05d' % (@testno ||= 0)
      ensure
        @testno += 1
      end

      def testing(*args, &block)
        method = ['test', testno, slug_for(*args)].delete_if(&:empty?).join('_')
        define_method(method, &block)
      end

      def test(*args, &block)
        testing(*args, &block)
      end

      def setup(&block)
        define_method(:setup, &block) if block
      end

      def teardown(&block)
        define_method(:teardown, &block) if block
      end

      def prepare(&block)
        @prepare ||= []
        @prepare.push(block) if block
        @prepare
      end

      def cleanup(&block)
        @cleanup ||= []
        @cleanup.push(block) if block
        @cleanup
      end
    end

    ## configure the subclass!
    #
    const_set(:Testno, '0')
    slug = slug_for(*args).tr('-', '_')
    name = ['TESTING', '%03d' % const_get(:Testno), slug].delete_if(&:empty?).join('_')
    name = name.upcase!
    const_set(:Name, name)
    const_set(:Missing, Object.new.freeze)

    ## instance methods
    #
    alias_method('__assert__', 'assert')

    def assert(*args, &block)
      if (args.size == 1) && args.first.is_a?(Hash)
        options = args.first
        expected = getopt(:expected, options) { missing }
        actual = getopt(:actual, options) { missing }
        if (expected == missing) && (actual == missing)
          actual, expected = options.to_a.flatten
        end
        expected = expected.call if expected.respond_to?(:call)
        actual = actual.call if actual.respond_to?(:call)
        assert_equal(expected, actual)
      end

      result = if block
                 label = "assert(#{args.join(' ')})"
                 result = nil
                 result = yield
                 __assert__(result, label)
                 result
               else
                 result = args.shift
                 label = "assert(#{args.join(' ')})"
                 __assert__(result, label)
                 result
      end
    end

    def missing
      self.class.const_get(:Missing)
    end

    def getopt(opt, hash, options = nil, &block)
      [opt.to_s, opt.to_s.to_sym].each do |key|
        return hash[key] if hash.key?(key)
      end
      default =
        if block
          yield
        else
          options.is_a?(Hash) ? options[:default] : nil
        end
      default
    end

    def subclass_of(exception)
      class << exception
        def ==(other)
          super || self > other
        end
      end
      exception
    end

    ##
    #
    module_eval(&block)

    setup
    prepare.each(&:call)

    at_exit do
      teardown
      cleanup.each(&:call)
    end

    self
  end
end

if $PROGRAM_NAME == __FILE__

  Testing 'Testing' do
    testing('foo') { assert true }
    test { assert true }
    p instance_methods.grep(/test/)
  end

end
