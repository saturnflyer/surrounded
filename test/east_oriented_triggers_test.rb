require "test_helper"

class EastTestContext
  extend Surrounded::Context
  east_oriented_triggers

  initialize :user, :other_user

  trigger :ask? do
    "asking a question..."
  end
end

describe Surrounded::Context, ".east_oriented_triggers" do
  let(:user) { User.new("Jim") }
  let(:other_user) { User.new("Guille") }
  let(:context) { EastTestContext.new(user: user, other_user: other_user) }

  it "returns the context object from trigger methods" do
    assert_equal context, context.ask?
  end
end

describe Surrounded::Context, ".east_oriented_triggers with protect_triggers" do
  let(:user) { User.new("Jim") }
  let(:other_user) { User.new("Guille") }
  let(:context) {
    ctxt = EastTestContext.new(user: user, other_user: other_user)
    ctxt.singleton_class.send(:protect_triggers)
    ctxt
  }

  it "returns the context object from trigger methods" do
    assert_equal context, context.ask?
  end
end
