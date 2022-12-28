require "test_helper"

describe Surrounded::Context, "#triggers" do
  let(:user) { User.new("Jim") }
  let(:other_user) { User.new("Guille") }
  let(:context) { TestContext.new(user: user, other_user: other_user) }

  it "lists the externally accessible trigger methods" do
    assert context.triggers.include?(:access_other_object)
  end

  it "prevents altering the list of triggers externally" do
    original_trigger_list = context.triggers
    context.triggers << "another_trigger"
    assert_equal original_trigger_list, context.triggers
  end
end

describe Surrounded::Context, ".triggers" do
  it "lists the externally accessible trigger methods" do
    assert TestContext.triggers.include?(:access_other_object)
  end

  it "prevents altering the list of triggers externally" do
    original_trigger_list = TestContext.triggers
    TestContext.triggers << "another_trigger"
    assert_equal original_trigger_list, TestContext.triggers
  end
end

describe Surrounded::Context, ".trigger" do
  let(:user) { User.new("Jim") }
  let(:other_user) { User.new("Guille") }
  let(:context) { TestContext.new(user: user, other_user: other_user) }

  it "defines a public method on the context" do
    assert context.respond_to?(:access_other_object)
  end

  it "gives objects access to each other inside the method" do
    assert_raises(NoMethodError) {
      user.other_user
    }
    assert_equal "Guille", context.access_other_object
  end

  it "preserves arguments and blocks" do
    result = context.block_method("argument") do |*args, obj|
      "Having an #{args.first} with #{obj.class}"
    end
    assert_equal "Having an argument with TestContext", result
  end

  it "allows usage of regular methods for triggers" do
    assert context.regular_method_trigger
  end

  it "ignores nil trigger names" do
    assert context.class.send(:trigger)
  end
end

describe Surrounded::Context, "#role?" do
  let(:user) {
    test_user = User.new("Jim")

    def test_user.get_role(name, context)
      context.role?(name) {}
    end

    test_user
  }
  let(:other_user) { User.new("Guille") }
  let(:external) {
    external_object = Object.new
    def external_object.get_role_from_context(name, context)
      context.role?(name) {}
    end
    external_object
  }
  let(:context) { TestContext.new(user: user, other_user: other_user) }

  it "returns the object assigned to the named role" do
    assert_equal user, user.get_role(:user, context)
  end

  it "returns false if the role does not exist" do
    refute user.get_role(:non_existant_role, context)
  end

  it "returns false if the accessing object is not a role player in the context" do
    refute external.get_role_from_context(:user, context)
  end

  it "checks for the role based upon the calling object" do
    refute context.role?(:user) {} # this test is the caller
  end
end

describe Surrounded::Context, "#role_player?" do
  let(:player) { User.new("Jim") }
  let(:other_player) { User.new("Amy") }
  let(:non_player) { User.new("Guille") }
  let(:context) { TestContext.new(user: player, other_user: other_player) }

  it "is true if the given object is a role player" do
    expect(context.role_player?(player)).must_equal true
  end

  it "is false if the given oject is not a role player" do
    expect(context.role_player?(non_player)).must_equal false
  end
end

class RoleAssignmentContext
  extend Surrounded::Context

  initialize(:user, :other_user)

  def user_ancestors
    user.singleton_class.ancestors
  end

  def other_user_ancestors
    other_user.singleton_class.ancestors
  end

  trigger def check_user_response
    user.respond_to?(:a_method!)
  end
  trigger :check_user_response # should not raise error

  trigger :check_other_user_response do
    user.respond_to?(:a_method!)
  end

  trigger :user_ancestors, :other_user_ancestors

  module User
    def a_method!
    end
  end

  module OtherUser
    def a_method!
    end
  end
end

class Special; end

class IgnoreExternalConstantsContext
  extend Surrounded::Context

  initialize :user, :special, :other

  role :other do
    def something_or_other
    end
  end

  trigger :check_special do
    special.class
  end
end

class ClassRoleAssignmentContext
  extend Surrounded::Context

  initialize(:thing, :the_test)

  trigger :check_user_response do
    the_test.assert_respond_to thing, :method_from_class
  end

  class Thing
    include Surrounded

    def initialize(obj)
      @obj = obj
    end

    def method_from_class
    end
  end
end

describe Surrounded::Context, "assigning roles" do
  include Surrounded # the test must be context-aware

  let(:user) { User.new("Jim") }
  let(:other_user) { CastingUser.new("Guille") }
  let(:context) { RoleAssignmentContext.new(user: user, other_user: other_user) }

  it "tries to use casting to add roles" do
    refute_includes(context.other_user_ancestors, RoleAssignmentContext::OtherUser)
  end

  it "extends objects with role modules failing casting" do
    assert_includes(context.user_ancestors, RoleAssignmentContext::User)
  end

  it "sets role players to respond to role methods" do
    assert context.check_user_response
    assert context.check_other_user_response
  end

  it "will use classes as roles" do
    user = User.new("Jim")

    context = ClassRoleAssignmentContext.new(thing: user, the_test: self)

    assert context.check_user_response
  end

  it "does not use constants defined outside the context class" do
    special = User.new("Special")
    other = User.new("Other")
    context = IgnoreExternalConstantsContext.new(user: user, special: special, other: other)
    assert_equal User, context.check_special
  end
end
