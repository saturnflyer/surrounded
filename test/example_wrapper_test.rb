require 'test_helper'

# If you want to use wrappers, here's how you could
class WrapperContext
  extend Surrounded::Context

  apply_roles_on(:trigger)
  initialize(:admin, :task)

  wrap :admin do
    def some_admin_method
      'hello from the admin wrapper!'
    end
  end
  wrap :task do; end

  trigger :do_something do
    admin.some_admin_method
  end
end

describe WrapperContext do
  let(:context){
    WrapperContext.new(Object.new, Object.new)
  }
  it 'wraps objects and allows them to respond to new methods' do
    assert_equal 'hello from the admin wrapper!', context.do_something
  end
end