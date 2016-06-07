require 'test_helper'
##
# The problem is as follows: When an object already contains a method
# that has the same name as an actor in the context, then the object
# defaults to its own method rather than calling the actor.
# This is simulated in the two classes below, where HasNameCollision has
# an empty attribute called will_collide (which is always nil). In the following
# context, when the method collide is called on the actor will_collide, the
# actor is ignored and the HasNameCollision#will_collide is called instead,
# returning nil.
##

class HasNameCollision
  include Surrounded

  attr_accessor :will_collide # should always return nil

  def assert_has_role
    true
  end

  def will_collide=(_); end
end

class ShouldCollide
  include Surrounded
  def collide
    return 'Method called in ShouldCollide'
  end
end

class ContextOverridesName
  extend Surrounded::Context

  # The specific behaviour we want to test is that when a role has a method that
  # has the same name as another role, then when that method is called strange
  # things happen.
  keyword_initialize :base, :will_collide
  on_name_collision :nothing

  trigger :check_setup do
    base.assert_has_role
  end

  trigger :induce_collision do
    base.name_collision
  end

  role :base do
    def name_collision
      will_collide.collide
    end

    def assert_has_role
      true
    end
  end
end

class ContextWithMultipleCollisions
  extend Surrounded::Context

  on_name_collision :warn

  keyword_initialize :first, :second, :third
end

class First

  def second;end
  def third;end
end

class Second
  def first;end

  def third;end
end

class Third
  def first;end
  def second;end

end

describe 'handling name collisions' do

  let(:new_context_with_collision){
    ContextOverridesName.new(base: HasNameCollision.new, will_collide: ShouldCollide.new)
  }

  after do
    ContextOverridesName.instance_eval{
      remove_instance_variable :@handler if defined?(@handler)
    }
  end

  def set_handler(handler)
    ContextOverridesName.instance_eval{
      on_name_collision handler
    }
  end

  it 'is works properly without handling collisions' do
    assert new_context_with_collision.check_setup
  end

  it 'allows a name collision' do
    err = assert_raises(NoMethodError){
      new_context_with_collision.induce_collision
    }
    assert_match(/undefined method \`collide' for nil:NilClass/, err.message)
  end

  it 'can raise an exception' do
    set_handler :raise
    assert_raises(ContextOverridesName::NameCollisionError){
      new_context_with_collision
    }
  end

  it 'can print a warning' do
    set_handler :warn
    assert_output(nil, "base has name collisions with [:will_collide]\n") {
      new_context_with_collision
    }
  end

  it 'can ignore collisions' do
    set_handler :nothing
    assert_output(nil, nil) {
      new_context_with_collision
    }
  end

  it 'raises an error with an unknown handler' do
    set_handler :barf
    err = assert_raises(ArgumentError) {
      new_context_with_collision
    }
    expect(err.message).must_match(/your name collision handler was set to \`barf' but there is no instance nor class method of that name/)
  end

  let(:create_context_with_multiple_collisions){
    ContextWithMultipleCollisions.new(first: First.new, second: Second.new, third: Third.new)
  }

  it 'can handle multiple collisions' do
    expected_message = <<ERR
first has name collisions with [:second, :third]
second has name collisions with [:first, :third]
third has name collisions with [:first, :second]
ERR
    assert_output(nil, expected_message){
      create_context_with_multiple_collisions
    }
  end

  it 'can use a class method' do
    class ContextOverridesName
      def self.class_method_handler(message)
        puts message
      end
    end
    set_handler :class_method_handler
    assert_output("base has name collisions with [:will_collide]\n"){
      new_context_with_collision
    }
  end

  it 'can use a proc' do
    set_handler ->(message){ puts "message from a proc: #{message}"}
    assert_output("message from a proc: base has name collisions with [:will_collide]\n"){
      new_context_with_collision
    }
  end
end
