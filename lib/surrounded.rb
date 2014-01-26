require "surrounded/version"
require "surrounded/context"

module Surrounded

  private

  def store_context(ctxt, &block)
    accessor = eval('self', block.binding)
    if accessor.role_player?(self)
      surroundings.unshift(ctxt)
    end
  end

  def remove_context(&block)
    accessor = eval('self', block.binding)
    if accessor.role_player?(self)
      surroundings.shift
    end
  end

  def surroundings
    @__surroundings__ ||= []
  end

  def context
    surroundings.first || NullContext.new
  end

  def method_missing(meth, *args, &block)
    context.role?(meth){} || super
  end

  def respond_to_missing?(meth, include_private=false)
    !!context.role?(meth){} || super
  end

  class NullContext
    def role?(*args)
      nil
    end
  end
end
