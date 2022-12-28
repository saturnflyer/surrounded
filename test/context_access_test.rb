require "test_helper"
require "minitest/mock"

class FilteredContext
  extend Surrounded::Context
  protect_triggers

  initialize :user, :other_user

  trigger :if_ready do
    "ready"
  end

  guard :if_ready do
    user.name != "Amy"
  end

  trigger :check_disallow_behavior do
    # used for disallow check
  end

  disallow :check_disallow_behavior do
    user.special
  end

  trigger :unguarded do
    # used for disallow check
  end

  role :user do
    def special
      "special user method"
    end
  end
end

describe Surrounded::Context, "access control" do
  let(:user) { User.new("Jim") }
  let(:other_user) { User.new("Guille") }
  let(:context) { FilteredContext.new(user: user, other_user: other_user) }

  it "includes triggers when allowed" do
    context.stub(:disallow_if_ready?, false) do
      assert context.triggers.include?(:if_ready)
    end
  end

  it "excludes triggers when not allowed" do
    refute context.triggers.include?(:if_ready)
  end

  it "raises error specific to the context class when trigger method not allowed" do
    error = assert_raises(::FilteredContext::AccessError) {
      context.if_ready
    }
    assert_match(/access to FilteredContext#if_ready is not allowed/i, error.message)
  end

  it "supports rescuing from Surrounded defined error when trigger method not allowed" do
    begin
      context.if_ready
    rescue ::Surrounded::Context::AccessError => error
      assert "rescued!"
    end
    assert_match(/access to FilteredContext#if_ready is not allowed/i, error.message)
  end

  it "applies roles in disallow blocks" do
    assert_equal "special user method", context.disallow_check_disallow_behavior?
  end

  it "lets you ask if the object will allow a method" do
    assert context.allow?(:unguarded)
    refute context.allow?(:check_disallow_behavior)
  end

  it "complains if you ask about an undefined method" do
    error = assert_raises(NoMethodError) {
      context.allow?(:not_a_defined_method)
    }
    assert_match(/undefined method `not_a_defined_method' for #<#{context.class}/, error.message)
  end
end
