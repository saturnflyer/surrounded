require 'test_helper'

class KeywordContext
  extend Surrounded::Context

  keyword_initialize(:user, :other_user) do
    @defined_by_initializer_block = 'yup'
  end
end

describe Surrounded::Context, '.initialize' do

  it 'applies a provided block to the instance' do
    context = KeywordContext.new(user: User.new('Jim'), other_user: User.new('Amy'))
    assert_equal 'yup', context.instance_variable_get(:@defined_by_initializer_block)
  end

  it 'keeps track of the original initialize arguments' do
    jim = User.new('Jim')
    amy = User.new('Amy')
    context = KeywordContext.new(user: jim, other_user: amy)
    tracked = context.send(:initializer_arguments)
    assert_equal jim, tracked[:user]
    assert_equal amy, tracked[:other_user]
  end

  it 'raises errors with missing keywords' do
    err = assert_raises(ArgumentError){
      KeywordContext.new(other_user: User.new('Amy'))
    }
    assert_match(/missing keyword: :?user/, err.message)
  end
end

class NonKeyworder
  extend Surrounded::Context

  initialize_without_keywords :this, :that do
    self.instance_variable_set(:@defined_by_initializer_block, 'yes')
  end

  trigger :access_other_object do
    that.name
  end
end

describe Surrounded::Context, 'non-keyword initializers' do
  it 'defines an initialize method accepting the same arguments' do
    assert_equal 2, NonKeyworder.instance_method(:initialize).arity
  end

  it 'works without keyword arguments' do
    assert NonKeyworder.new(User.new('Jim'), User.new('Guille'))
  end

  it 'evaluates a given block' do
    assert_equal 'yes', NonKeyworder.new(User.new('Jim'), User.new('Guille')).instance_variable_get(:@defined_by_initializer_block)
  end

  it 'allows rebinding with a hash' do
    context = NonKeyworder.new(User.new('Jim'), User.new('Guille'))
    expect(context.access_other_object).must_equal 'Guille'
    context.rebind(this: User.new('Amy'), that: User.new('Elizabeth'))
    expect(context.access_other_object).must_equal 'Elizabeth'
  end
end
