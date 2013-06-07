require 'test_helper'
require 'surrounded'
require 'surrounded/context'

User = Struct.new(:name)
class User
  include Surrounded
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
  user       = User.new("Jim")
  other_user = User.new("Guille")

  it "should have certain objects inside" do

    use_case = SampleUseCase.new(user, other_user)
    assert use_case.be_polite == "Hi #{other_user.name}, I am #{user.name}"
  end
end
