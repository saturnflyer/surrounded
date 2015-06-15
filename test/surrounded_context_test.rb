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

  it 'preserves arguments and blocks' do
    result = context.block_method('argument') do |*args, obj|
      "Having an #{args.first} with #{obj.class}"
    end
    assert_equal "Having an argument with TestContext", result
  end

  it 'allows usage of regular methods for triggers' do
    assert context.regular_method_trigger
  end

  it 'ignores nil trigger names' do
    assert context.class.send(:trigger)
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

  initialize(:user, :other_user) do
    self.instance_variable_set(:@defined_by_initializer_block, 'yup')
  end

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
    def a_method!; end
  end
  module OtherUser
    def a_method!; end
  end
end

class Special; end
class IgnoreExternalConstantsContext
  extend Surrounded::Context

  initialize :user, :special, :other

  role :other do
    def something_or_other; end
  end

  trigger :check_special do
    special.class
  end
end

describe Surrounded::Context, '.initialize' do
  it 'defines an initialize method accepting the same arguments' do
    assert_equal 2, RoleAssignmentContext.instance_method(:initialize).arity
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
    def initialize(obj); end
    def method_from_class; end
  end

end

describe Surrounded::Context, 'assigning roles' do
  include Surrounded # the test must be context-aware

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
    user = User.new('Jim')

    context = ClassRoleAssignmentContext.new(user, self)

    assert context.check_user_response
  end

  it 'does not use constants defined outside the context class' do
    special = User.new('Special')
    other = User.new('Other')
    context = IgnoreExternalConstantsContext.new(user, special, other)
    assert_equal User, context.check_special
  end

  it 'applies a provided block to the instance' do
    assert_equal 'yup', context.instance_variable_get(:@defined_by_initializer_block)
  end
end

class BareObjectContext
  extend Surrounded::Context

  initialize_without_keywords :number, :string, :user

  role :user do
    def output
      [number.to_s, string, name].join(' - ')
    end
  end

  trigger :output do
    user.output
  end
end

describe Surrounded::Context, 'skips affecting non-surrounded objects' do
  it 'works with non-surrounded objects' do
    context = BareObjectContext.new(123,'hello', User.new('Jim'))
    assert_equal '123 - hello - Jim', context.output
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

  role :others do; end
  role :other do; end

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

describe Surrounded::Context, 'reusing context object' do
  let(:user){ User.new("Jim") }
  let(:other_user){ User.new("Guille") }
  let(:context){ TestContext.new(user, other_user) }

  it 'allows rebinding new players' do
    expect(context.access_other_object).must_equal 'Guille'
    context.rebind(user: User.new('Amy'), other_user: User.new('Elizabeth'))
    expect(context.access_other_object).must_equal 'Elizabeth'
  end

  it 'clears internal storage when rebinding' do
    originals = context.instance_variables.map{|var| context.instance_variable_get(var) }
    context.rebind(user: User.new('Amy'), other_user: User.new('Elizabeth'))
    new_ivars = context.instance_variables.map{|var| context.instance_variable_get(var) }
    originals.zip(new_ivars).each do |original_ivar, new_ivar|
      expect(original_ivar).wont_equal new_ivar
    end
  end
end

begin
  class Keyworder
    extend Surrounded::Context

    keyword_initialize :this, :that do
      self.instance_variable_set(:@defined_by_initializer_block, 'yes')
    end
  end

  describe Surrounded::Context, 'keyword initializers' do
    it 'works with keyword arguments' do
      assert Keyworder.new(this: User.new('Jim'), that: User.new('Guille'))
    end

    it 'raises errors with missing keywords' do
      err = assert_raises(ArgumentError){
        Keyworder.new(this: User.new('Amy'))
      }
      assert_match(/missing keyword: that/, err.message)
    end

    it 'evaluates a given block' do
      assert_equal 'yes', Keyworder.new(this: User.new('Jim'), that: User.new('Guille')).instance_variable_get(:@defined_by_initializer_block)
    end
  end
rescue SyntaxError
  STDOUT.puts "No support for keywords"
end
