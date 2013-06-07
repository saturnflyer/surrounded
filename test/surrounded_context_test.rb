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

  it 'gives objects access to each other inside the method' do
    assert_raises(NoMethodError){
      user.other_user
    }
    assert_equal "Guille", context.access_other_object
  end
end