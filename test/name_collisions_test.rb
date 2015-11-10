require 'test_helper'
require 'byebug'

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


# Just check that the basic context is properly set up first
describe Surrounded::Context, 'context correctly set up' do

    let(:has_collision){
      ContextOverridesName.new(base: HasNameCollision.new, will_collide: ShouldCollide.new)
    }

    it 'is surrounded' do
      assert has_collision.check_setup
    end

    it 'has a name collision' do
      begin
      assert_match 'Method in the role class',has_collision.induce_collision, "Was: #{has_collision.induce_collision || 'nil'}"
      rescue NoMethodError => ex
        assert 'NoMethodError called'
      end
    end
end
