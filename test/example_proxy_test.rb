require 'test_helper'

if test_rebinding_methods?

# If you want to use wrappers, here's how you could
class ProxyContext
  extend Surrounded::Context

  apply_roles_on(:trigger)
  initialize(:admin, :task)

  interface :admin do
    def some_admin_method
      "hello from #{name}, the admin interface!"
    end
  end

  trigger :do_something do
    admin.some_admin_method
  end

  trigger :admin_name do
    admin.name
  end

  trigger :admin_missing_method do
    admin.method_that_does_not_exist
  end
end

ProxyUser = Struct.new(:name)

describe ProxyContext do
  let(:user){
    ProxyUser.new('Jim')
  }
  let(:context){
    ProxyContext.new(user, Object.new)
  }
  it 'proxys methods between objects and its interface' do
    assert_equal 'hello from Jim, the admin interface!', context.do_something
  end

  it 'forwards methods that the object responds to' do
    assert_equal 'Jim', context.admin_name
  end

  it 'passes missing methods up the ancestry of the object' do
    err = ->{ context.admin_missing_method }.must_raise(NoMethodError)

    assert_match 'ProxyUser name="Jim"', err.message
  end
end

end