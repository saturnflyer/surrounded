require 'test_helper'

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

    def combined_methods
      some_admin_method
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

  trigger :admin_responds? do
    admin.respond_to?(:talking_to_others)
  end

  trigger :get_admin_method do
    admin.method(:talking_to_others)
  end

  trigger :combined_interface_methods do
    admin.combined_methods
  end
end

ProxyUser = Class.new do
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

  it 'fails access to other objects in the context' do
    err = _{ context.talking }.must_raise NameError
    assert_match(%r{undefined local variable or method `task'}, err.message)
  end

  it 'sets roles to respond to role methods' do
    assert context.admin_responds?
  end

  # A Negotiator object merely applies methods to another object
  # so that once the method is called, the object has no knowledge
  # of the module from which the method was applied.
  it 'does not find other interface methods' do
    assert_raises(NameError){
      context.combined_interface_methods
    }
  end

  it 'is able to grab methods from the object' do
    assert_equal :talking_to_others, context.get_admin_method.name
  end

  it 'allows Surrounded objects to interact with others' do
    assert context.rebind(user: User.new('Surrounded'), task: task).talking
  end

  it 'works with frozen and primitive objects' do
    context.rebind(admin: "brrr".freeze, task: task)
    assert context.get_admin_method
    context.rebind(admin: nil, task: task)
    assert context.get_admin_method
    context.rebind(admin: true, task: task)
    assert context.get_admin_method
  end
end
