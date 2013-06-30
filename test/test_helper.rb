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

  setup(:user, :other_user)

  trigger :access_other_object do
    user.other_user.name
  end
end