require "surrounded/version"

module Surrounded
  private

  def method_missing(meth, *args, &block)
    context.role?(meth, self) || super
  end

  def respond_to_missing?(meth, include_private=false)
    !!context.role?(meth, self) || super
  end

  def context
    Thread.current[:context] ||= []
    Thread.current[:context].first || NullContext.new
  end

  class NullContext < BasicObject
    def role?(*args)
      nil
    end
  end
end
