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

  def will_collide=(val); end

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
  def second
  end

  def third
  end
end

class Second

  def first
  end

  def third
  end
end

class Third

  def first
  end

  def second
  end

end


# Just check that the basic context is properly set up first
describe Surrounded::Context, 'context correctly set up' do

  let(:has_collision){
    ContextOverridesName.new(base: HasNameCollision.new, will_collide: ShouldCollide.new)
  }

  let(:multiple_collisions){
    ContextWithMultipleCollisions.new(first: First.new, second: Second.new, third: Third.new)
  }

  after do
    ContextOverridesName.instance_eval{
      on_name_collision :nothing
    }
  end

  it 'is surrounded' do
    assert has_collision.check_setup
  end

  it 'has a name collision' do
    begin
      assert_match 'Method in the role class',has_collision.induce_collision, "Was: #{has_collision.induce_collision || 'nil'}"
    rescue NoMethodError => ex
      ex.message
      assert 'NoMethodError called'
    end
  end

  it 'can raise an exception' do
    set_handler :raise_exception
    assert_raises(Surrounded::Context::NameCollisionError){
      has_collision
    }
  end

  it 'can print a warning' do
    set_handler :warn
    assert_output(stdout = "base has name collisions with [:will_collide]\n") {has_collision}
  end

  it 'can take a lambda' do
    has_worked = false
    set_handler lambda {|role, array| has_worked = true}
    has_collision
    assert has_worked
  end

  it 'can handle multiple collisions' do
    assert_output(stdout = "first has name collisions with [:second, :third]\nsecond has name collisions with [:first, :third]\nthird has name collisions with [:first, :second]\n"){multiple_collisions}
  end

  it 'can use a class method' do
    class ContextOverridesName
      def class_method_handler(role, colliders)
        puts "class method called"
      end
    end
    set_handler :class_method_handler
    assert_output(stdout = "class method called\n"){has_collision}
  end

  def set_handler(handler)
    ContextOverridesName.instance_eval{
      on_name_collision handler
    }
  end

end
