require 'simplecov'
require 'minitest/autorun'
require 'coveralls'

if ENV['COVERALLS']
  Coveralls.wear!
end

require 'surrounded'
require 'surrounded/context'

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
end

# This is a different implementation of module_method_rebinding?
# created in order to check that the behavior of the code is correct.
#
# This method is used in tests and module_method_rebinding? is used
# in the library code.
def test_rebinding_methods?
  unbound = Enumerable.instance_method(:count)
  unbound.bind(Object.new)
  true
rescue TypeError
  false
end