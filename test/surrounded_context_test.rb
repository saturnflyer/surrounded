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
class CastingUser < User
  include Casting::Client
  delegate_missing_methods
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
  
  def regular_method_trigger
    user.respond_to?(:a_method!)
  end
  
  trigger :user_ancestors, :other_user_ancestors, :regular_method_trigger

  module User
    def a_method!; end
  end
  module OtherUser
    def a_method!; end
  end
end

describe Surrounded::Context, '.initialize' do
  it 'defines an initialize method accepting the same arguments' do
    assert_equal 2, RoleAssignmentContext.instance_method(:initialize).arity
  end
end

describe Surrounded::Context, 'assigning roles' do
  include Surrounded
  let(:user){ User.new("Jim") }
  let(:other_user){ CastingUser.new("Guille") }
  let(:context){ RoleAssignmentContext.new(user, other_user) }

  it 'tries to use casting to add roles' do
    refute_includes(context.other_user_ancestors, RoleAssignmentContext::OtherUser)
  end

  it 'extends objects with role modules failing casting' do
    assert_includes(context.user_ancestors, RoleAssignmentContext::User)
  end

  it 'sets role players to respond to role methods' do
    assert context.check_user_response
    assert context.check_other_user_response
  end

  it 'will use classes as roles' do
    ClassRoleAssignmentContext = Class.new do
      extend Surrounded::Context

      initialize(:thing, :the_test)

      trigger :check_user_response do
        the_test.assert_respond_to thing, :method_from_class
      end

      class Thing
        include Surrounded
        def initialize(obj); end
        def method_from_class; end
      end

    end

    user = User.new('Jim')

    context = ClassRoleAssignmentContext.new(user, self)

    assert context.check_user_response
  end

  it 'allows usage of regular methods for triggers' do
    assert context.regular_method_trigger
  end

  it 'ignores nil trigger names' do
    assert context.class.send(:trigger)
  end
end

class CollectionContext
  extend Surrounded::Context

  initialize :members, :others

  trigger :get_members_count do
    members.member_count
  end

  trigger :get_member_show do
    members.map(&:show).join(', ')
  end

  role :members do
    def member_count
      size
    end
  end

  role :member do
    def show
      "member show"
    end
  end

end

describe Surrounded::Context, 'auto-assigning roles for collections' do
  let(:member_one){ User.new('Jim') }
  let(:member_two){ User.new('Amy') }
  let(:members){ [member_one, member_two] }

  let(:other_one){ User.new('Guille') }
  let(:other_two){ User.new('Jason') }
  let(:others){ [other_one, other_two] }

  let(:context){ CollectionContext.new(members, others) }

  it 'assigns the collection role to collections' do
    assert_equal members.size, context.get_members_count
  end

  it 'assigns a defined role to each item in a role player collection' do
    assert_equal "member show, member show", context.get_member_show
  end
end
