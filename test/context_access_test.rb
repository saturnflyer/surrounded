require 'test_helper'
require 'minitest/mock'

class FilteredContext
  extend Surrounded::Context
  protect_triggers
  
  initialize :user, :other_user
  
  trigger :if_ready do
    'ready'
  end
  
  disallow :if_ready do
    user.name != 'Amy'
  end
end

describe Surrounded::Context, 'access control' do
  let(:user){ User.new("Jim") }
  let(:other_user){ User.new("Guille") }
  let(:context){ FilteredContext.new(user, other_user) }
  
  it 'includes triggers when allowed' do
    context.stub(:disallow_if_ready?, false) do
      assert context.triggers.include?(:if_ready)
    end
  end

  it 'excludes triggers when not allowed' do
    refute context.triggers.include?(:if_ready)
  end
  
  it 'raises errors when trigger method not allowed' do
    error = assert_raises(::Surrounded::Context::AccessError){
      context.if_ready
    }
    assert_match(/access to FilteredContext#if_ready is not allowed/i, error.message)
  end
end