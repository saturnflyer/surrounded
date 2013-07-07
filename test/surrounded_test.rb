require 'test_helper'

describe "Surrounded", 'without context' do

  let(:jim){ User.new("Jim") }

  it "never has context roles" do
    assert_nil jim.send(:context).role?('anything')
  end

end

describe "Surrounded" do
  let(:jim){ User.new("Jim") }
  let(:guille){ User.new("Guille") }
  let(:external_user){ User.new("External User") }

  let(:context){
    TestContext.new(jim, guille)
  }

  before do
    jim.store_context(context)
    guille.store_context(context)
  end

  it "has access to objects in the context" do
    assert_equal jim.other_user, guille
  end

  it "responds to messages for roles on the context" do
    assert jim.respond_to?(:other_user)

    jim.remove_context

    refute jim.respond_to?(:other_user)
  end

  it "prevents access to context objects for external objects" do
    assert_raises(NoMethodError){
      external_user.user
    }
  end
end

describe "Surrounded", "added to an existing object" do
  it "allows the object to store its context" do
    object = Object.new
    assert_raises(NoMethodError){
      object.store_context(self)
    }
    object.extend(Surrounded)
    assert object.store_context(self)
    assert object.remove_context
  end
end

module SpecialSurrounding
  include Surrounded
end

describe "Surrounded", "added to an object through another module" do
  it "allows the object to store its context" do
    object = Array.new
    assert_raises(NoMethodError){
      object.store_context(self)
    }
    object.extend(SpecialSurrounding)
    assert object.store_context(self)
    assert object.remove_context
    assert object.send(:context)
  end
end