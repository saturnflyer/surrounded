require "surrounded/version"

module Surrounded
  def self.included(klass)
    klass.class_eval{
      extend Surrounded::Contextual
    }
  end

  module Contextual
    def new(*args)
      instance = super
      instance.instance_variable_set(:@__surroundings__, [])
      instance
    end
  end

  def store_context(ctxt)
    surroundings.unshift(ctxt)
  end

  def remove_context(ctxt)
    surroundings.shift
  end

  private

  def method_missing(meth, *args, &block)
    context.role?(meth){} || super
  end

  def respond_to_missing?(meth, include_private=false)
    !!context.role?(meth){} || super
  end

  def context
    Array(surroundings).first || NullContext.new
  end

  def surroundings
    @__surroundings__
  end

  class NullContext < BasicObject
    def role?(*args)
      nil
    end
  end
end
