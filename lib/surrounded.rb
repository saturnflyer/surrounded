require "surrounded/version"

module Surrounded
  def self.included(klass)
    klass.class_eval {
      extend Surrounded::Contextual
    }
    unless klass.is_a?(Class)
      def klass.extended(object)
        Surrounded.create_surroundings(object)
      end
    end
  end

  def self.extended(object)
    Surrounded.create_surroundings(object)
  end

  module Contextual
    def new(*args)
      instance = super
      Surrounded.create_surroundings(instance)
      instance
    end
  end

  def store_context(ctxt)
    surroundings.unshift(ctxt)
  end

  def remove_context
    surroundings.shift
  end

  private

  def self.create_surroundings(obj)
    obj.instance_variable_set(:@__surroundings__, [])
  end

  def method_missing(meth, *args, &block)
    context.role?(meth){} || super
  end

  def respond_to_missing?(meth, include_private=false)
    !!context.role?(meth){} || super
  end

  def context
    surroundings.first || NullContext.new
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
