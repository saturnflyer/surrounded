require 'test_helper'

class InitContext
  extend Surrounded::Context

  initialize(:user, :other_user) do
    @defined_by_initializer_block = 'yup'
  end
end

describe Surrounded::Context, '.initialize' do
  it 'defines an initialize method accepting the same arguments' do
    assert_equal 2, InitContext.instance_method(:initialize).arity
  end

  it 'applies a provided block to the instance' do
    context = InitContext.new(User.new('Jim'), User.new('Amy'))
    assert_equal 'yup', context.instance_variable_get(:@defined_by_initializer_block)
  end
end

begin
  class Keyworder
    extend Surrounded::Context

    keyword_initialize :this, :that do
      self.instance_variable_set(:@defined_by_initializer_block, 'yes')
    end
  end

  describe Surrounded::Context, 'keyword initializers' do
    it 'works with keyword arguments' do
      assert Keyworder.new(this: User.new('Jim'), that: User.new('Guille'))
    end

    it 'raises errors with missing keywords' do
      err = assert_raises(ArgumentError){
        Keyworder.new(this: User.new('Amy'))
      }
      assert_match(/missing keyword: that/, err.message)
    end

    it 'evaluates a given block' do
      assert_equal 'yes', Keyworder.new(this: User.new('Jim'), that: User.new('Guille')).instance_variable_get(:@defined_by_initializer_block)
    end
  end
rescue SyntaxError
  STDOUT.puts "No support for keywords"
end