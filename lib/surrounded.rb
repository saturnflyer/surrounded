require "surrounded/version"

module Surrounded
  private

  def method_missing(meth, *args, &block)
    if context.respond_to?(meth)
      context.send(meth, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(meth, include_private=false)
    context.respond_to?(meth, include_private) || super
  end

  def context
    Thread.current[:context] ||= []
    Thread.current[:context].first || NullContext.new
  end

  class NullContext < BasicObject
    def respond_to?(*args)
      false
    end
  end
end
