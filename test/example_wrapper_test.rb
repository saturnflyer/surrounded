require "test_helper"

# If you want to use wrappers, here's how you could
class WrapperContext
  extend Surrounded::Context

  initialize(:admin, :task)

  wrap :admin do
    def some_admin_method
      "hello from the admin wrapper!"
    end
  end
  wrap :task, &proc {}

  trigger :do_something do
    admin.some_admin_method
  end
end

describe WrapperContext do
  let(:context) {
    WrapperContext.new(admin: Object.new, task: Object.new)
  }
  it "wraps objects and allows them to respond to new methods" do
    assert_equal "hello from the admin wrapper!", context.do_something
  end
end
