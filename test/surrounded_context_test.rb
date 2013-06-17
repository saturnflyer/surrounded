require 'test_helper'

describe Surrounded::Context, '#triggers' do
  let(:user){ User.new("Jim") }
  let(:other_user){ User.new("Guille") }
  let(:context){ TestContext.new(user, other_user) }

  it 'lists the externally accessible trigger methods' do
    assert context.triggers.include?(:access_other_object)
  end

  it 'prevents altering the list of triggers externally' do
    original_trigger_list = context.triggers
    context.triggers << 'another_trigger'
    assert_equal original_trigger_list, context.triggers
  end
end

describe Surrounded::Context, '.triggers' do
  it 'lists the externally accessible trigger methods' do
    assert TestContext.triggers.include?(:access_other_object)
  end

  it 'prevents altering the list of triggers externally' do
    original_trigger_list = TestContext.triggers
    TestContext.triggers << 'another_trigger'
    assert_equal original_trigger_list, TestContext.triggers
  end
end

describe Surrounded::Context, '.trigger' do
  let(:user){ User.new("Jim") }
  let(:other_user){ User.new("Guille") }
  let(:context){ TestContext.new(user, other_user) }

  it 'defines a public method on the context' do
    assert context.respond_to?(:access_other_object)
  end

  it 'gives objects access to each other inside the method' do
    assert_raises(NoMethodError){
      user.other_user
    }
    assert_equal "Guille", context.access_other_object
  end
end

describe Surrounded::Context, '#role?' do
  let(:user){
    test_user = User.new("Jim")

    def test_user.get_role(name, context)
      context.role?(name){}
    end

    test_user
  }
  let(:other_user){ User.new("Guille") }
  let(:external){
    external_object = Object.new
    def external_object.get_role_from_context(name, context)
      context.role?(name){}
    end
    external_object
  }
  let(:context){ TestContext.new(user, other_user) }

  it 'returns the object assigned to the named role' do
    assert_equal user, user.get_role(:user, context)
  end

  it 'returns false if the role does not exist' do
    refute user.get_role(:non_existant_role, context)
  end

  it 'returns false if the accessing object is not a role player in the context' do
    refute external.get_role_from_context(:user, context)
  end

  it 'checks for the role based upon the calling object' do
    refute context.role?(:user){} # this test is the caller
  end
end

require 'casting'
CastingUser = Struct.new(:name)
class CastingUser
  include Casting::Client
  delegate_missing_methods
end

class RoleAssignmentContext
  extend Surrounded::Context

  setup(:user, :other_user)

  trigger :user_ancestors do
    user.singleton_class.ancestors
  end

  trigger :other_user_ancestors do
    other_user.singleton_class.ancestors
  end

  trigger :check_user_response do
    user.respond_to?(:a_method!)
  end

  trigger :check_other_user_response do
    user.respond_to?(:a_method!)
  end

  module User
    def a_method!; end
  end
  module OtherUser
    def a_method!; end
  end
end

describe Surrounded::Context, '.setup' do
  it 'defines an initialize method accepting the same arguments' do
    skip "not yet implemented. may not be possible"
    assert_equal 2, RoleAssignmentContext.instance_method(:initialize).arity
  end
end

describe Surrounded::Context, 'assigning roles' do
  let(:user){ CastingUser.new("Jim") }
  let(:other_user){ User.new("Guille") }
  let(:context){ RoleAssignmentContext.new(user, other_user) }

  it 'tries to use casting to add roles' do
    refute_includes(context.user_ancestors, RoleAssignmentContext::User)
  end

  it 'extends objects with role modules failing casting' do
    assert_includes(context.other_user_ancestors, RoleAssignmentContext::OtherUser)
  end

  it 'sets role players to respond to role methods' do
    assert context.check_user_response
    assert context.check_other_user_response
  end

  it 'will not use classes as roles' do
    ClassRoleAssignmentContext = Class.new do
      extend Surrounded::Context

      setup(:thing, :the_test)

      trigger :check_user_response do
        the_test.refute thing.respond_to?(:method_from_class), 'did respond to :method_from_class'
      end

      class Thing
        def method_from_class; end
      end

    end

    user = User.new('Jim')

    context = ClassRoleAssignmentContext.new(user, self)

    context.check_user_response
  end
end