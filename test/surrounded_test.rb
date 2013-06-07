require 'test_helper'

User = Struct.new(:name)
class User
  include Surrounded
end

class TestContext
  extend Surrounded::Context

  setup(:user, :other_user)
end

describe "Surrounded" do
  let(:jim){ User.new("Jim") }
  let(:guille){ User.new("Guille") }
  let(:external_user){ User.new("External User") }

  let(:context){
    TestContext.new(jim, guille)
  }

  before do
    Thread.current[:context] = [context]
  end

  it "has access to objects in the context" do
    assert_equal jim.other_user, guille
  end

  it "responds to messages for roles on the context" do
    assert jim.respond_to?(:other_user)

    Thread.current[:context] = []

    refute jim.respond_to?(:other_user)
  end

  it "prevents access to context objects for external objects" do
    assert_raises(NoMethodError){
      external_user.user
    }
  end
end