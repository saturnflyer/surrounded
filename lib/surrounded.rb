require "surrounded/version"
require "surrounded/context"
require "singleton"

# This module should be added to objects which will enter
# into context objects.
#
# Its main purpose is to keep a reference to the context
# and to implement method_missing to handle the relationship
# to other objects in the context.
module Surrounded
  private

  def store_context(&block)
    accessor = block.binding.eval("self")
    surroundings.unshift(accessor)
    self
  end

  def remove_context(&block)
    accessor = block.binding.eval("self")
    surroundings.shift if surroundings.include?(accessor)
    self
  end

  def surroundings
    @__surroundings__ ||= []
  end

  def context
    surroundings.first || NullContext.instance
  end

  def method_missing(meth, *args, &block)
    context.role?(meth) {} || super
  end

  def respond_to_missing?(meth, include_private = false)
    !!context.role?(meth) {} || super
  end

  class NullContext
    include Singleton

    def role?(*args)
      nil
    end
  end
end
