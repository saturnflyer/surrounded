require 'test_helper'
require 'surrounded'
require 'surrounded/context'

class User
  include Surrounded
  attr_accessor :name
end

class SampleUseCase
  extend Surrounded::Context

  setup(:user, :other_user)

  trigger :be_polite do
    user.say_hello
  end

  module User
    def say_hello
      "Hi #{other_user.name}, I am #{user.name}"
    end
  end
end

describe "An evironment" do
  user       = User.new
  other_user = User.new

  it "should have certain objects inside" do
    user.name       = "Jim"
    other_user.name = "Guille"

    use_case = SampleUseCase.new(user, other_user)
    assert use_case.be_polite == "Hi #{other_user.name}, I am #{user.name}"
  end
end
