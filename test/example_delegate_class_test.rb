require 'test_helper'

# If you want to use wrappers, here's how you could
class DelegateClassContext
  extend Surrounded::Context

  initialize(:user, :task)

  delegate_class :user, 'User' do
    def some_admin_method
      'hello from the admin DelegateClass wrapper!'
    end
  end
  wrap :task do
  end

  trigger :do_something do
    user.some_admin_method
  end
end

describe DelegateClassContext do
  let(:context){
    DelegateClassContext.new(user: User.new('jim'), task: Object.new)
  }
  it 'wraps objects using DelegateClass' do
    assert_equal 'hello from the admin DelegateClass wrapper!', context.do_something
  end
end