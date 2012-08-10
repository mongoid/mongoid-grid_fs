require_relative 'helper'

Testing Mongoid::Sequence do
##
#
  Sequence =
    Mongoid::Sequence

  SequenceGenerator =
    Mongoid::SequenceGenerator

  prepare do
    SequenceGenerator.destroy_all
  end

##
#
  test 'can be included' do
    assert do
      model_class do
        include Mongoid::Sequence
      end
    end
  end

  test 'provided a "sequence" class method that builds a field' do
    m =
      assert do
        model_class do
          include Mongoid::Sequence

          sequence 'number'
        end
      end

    assert{ m.fields['number'].name == 'number' }
  end

  test 'autoincrements the field on create' do
    m =
      assert do
        model_class do
          include Mongoid::Sequence

          sequence 'number'
        end
      end

    10.times do |i|
      assert{ m.create.number == i.succ }
    end
  end

  test 'allows the sequence to be reset' do
    m =
      assert do
        model_class do
          include Mongoid::Sequence

          sequence 'number'
        end
      end

    assert{ m.sequence_for(:number).reset! }
    assert{ m.sequence_for(:number).next == 1 }
    assert{ m.sequence_for(:number).next != 1 }
    assert{ m.sequence_for(:number).reset! }
    assert{ m.sequence_for(:number).next == 1 }
  end



protected
  def model_class(&block)
    m = Class.new
    m.class_eval do
      def m.name() 'm' end
      include Mongoid::Document
    end
    m.destroy_all
    m.class_eval(&block) if block
    m
  end
end
