require 'test_helper'

# If you want to use wrappers, here's how you could
class ProxyContext
  extend Surrounded::Context

  initialize(:admin, :task)

  interface :admin do
    def some_admin_method
      "hello from #{name}, the admin interface!"
    end

    def talking_to_others
      task.name
    end
  end

  wrap :task do
  end

  trigger :do_something do
    admin.some_admin_method
  end

  trigger :talking do
    admin.talking_to_others
  end

  trigger :admin_name do
    admin.name
  end

  trigger :admin_missing_method do
    admin.method_that_does_not_exist
  end
end

ProxyUser = Class.new do
  include Surrounded
  def initialize(name)
    @name = name
  end
  attr_reader :name
end

describe ProxyContext do
  let(:user){
    ProxyUser.new('Jim')
  }
  let(:task){
    OpenStruct.new(name: 'GTD')
  }
  let(:context){
    ProxyContext.new(user, task)
  }
  it 'proxys methods between objects and its interface' do
    assert_equal 'hello from Jim, the admin interface!', context.do_something
  end

  it 'forwards methods that the object responds to' do
    assert_equal 'Jim', context.admin_name
  end

  it 'passes missing methods up the ancestry of the object' do
    err = ->{ context.admin_missing_method }.must_raise(NoMethodError)

    assert_match(/ProxyUser.*name="Jim"/, err.message)
  end

  it 'allows access to other objects in the context' do
    assert_equal 'GTD', context.talking
  end
end
