require "simplecov"
require "minitest/autorun"
SimpleCov.enable_coverage :branch
SimpleCov.add_filter %r{version.rb}
SimpleCov.start unless defined?(Coverage)

require "ostruct"
require "surrounded"
require "surrounded/context"

class User
  include Surrounded

  def initialize(name)
    @name = name
  end
  attr_reader :name
end

class TestContext
  extend Surrounded::Context

  initialize(:user, :other_user)

  trigger :access_other_object do
    user.other_user.name
  end

  def block_method(*args, &block)
    block.call(*args, self)
  end
  trigger :block_method

  def regular_method_trigger
    true
  end
  trigger :regular_method_trigger
end
