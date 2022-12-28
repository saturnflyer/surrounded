require "test_helper"

describe "Surrounded", "without context" do
  let(:jim) { User.new("Jim") }

  it "never has context roles" do
    assert_nil jim.send(:context).role?("anything")
  end
end

describe "Surrounded" do
  let(:jim) { User.new("Jim") }
  let(:guille) { User.new("Guille") }
  let(:external_user) { User.new("External User") }

  let(:context) {
    TestContext.new(user: jim, other_user: guille)
  }

  it "has access to objects in the context" do
    assert context.access_other_object
  end

  it "prevents access to context objects for external objects" do
    assert_raises(NoMethodError) {
      external_user.user
    }
  end
end

class UnsurroundedObject
  attr_accessor :name
end

describe "Surrounded", "added to an existing object" do
  it "allows the object to store its context" do
    thing = UnsurroundedObject.new
    thing.name = "Jim"

    assert_raises(NoMethodError) {
      thing.__send__(:store_context)
    }
    thing.extend(Surrounded)

    other = User.new("Guille")

    context = TestContext.new(user: thing, other_user: other)
    assert context.access_other_object
  end
end

module SpecialSurrounding
  include Surrounded
end

describe "Surrounded", "added to an object through another module" do
  it "allows the object to store its context" do
    object = []
    object.extend(SpecialSurrounding)
    assert object.respond_to?(:context, true)
  end
end
