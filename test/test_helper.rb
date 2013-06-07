require 'minitest/autorun'
require 'simplecov'
require 'coveralls'

if ENV['COVERALLS']
  Coveralls.wear!
else
  SimpleCov.start do
    add_filter 'test'
  end
end

require 'surrounded'
require 'surrounded/context'

User = Struct.new(:name)
class User
  include Surrounded
end

class TestContext
  extend Surrounded::Context

  setup(:user, :other_user)

  trigger :access_other_object do
    user.other_user.name
  end
end