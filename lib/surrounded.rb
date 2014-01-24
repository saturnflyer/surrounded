require "surrounded/version"
require "surrounded/context"

module Surrounded
  def self.included(klass)
    klass.class_eval {
      extend Surrounded::Contextual
    }
  end

  module Contextual
  end

  def store_context(ctxt)
    surroundings.unshift(ctxt)
  end

  def remove_context
    surroundings.shift
  end

  private

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
