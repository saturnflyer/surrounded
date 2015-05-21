module Surrounded
  module Context
    class Negotiator
      class << self
        # Return a class which has methods defined to forward the method to
        # the wrapped object delegating to the behavior module.
        # This prevents hits to method_missing.
        def for_role(mod)
          klass = Class.new(self)
          mod.instance_methods(false).each do |meth|
            num = __LINE__; klass.class_eval %{
              def #{meth}(*args, &block)
                @behaviors.instance_method(:#{meth}).bind(@object).call(*args, &block)
              end
            }, __FILE__, num
          end
          klass
        end
      end


      identity = %w[__send__ object_id]
      method_access = %w[respond_to? method]

      reserved_methods = (identity + method_access).join('|')

      # Remove all methods except the identity methods
      instance_methods.reject{ |m|
        m.to_s =~ /#{reserved_methods}/
      }.each do |meth|
        undef_method meth
      end

      private

      def initialize(object, behaviors)
        @object, @behaviors = object, behaviors
      end

      def method_missing(meth, *args, &block)
        @object.send(meth, *args, &block)
      end

      def respond_to_missing?(meth, include_private=false)
        @object.respond_to?(meth, include_private)
      end
    end

    # The method_missing definition from Surrounded will apply
    # before the one defined above. This allows the methods for
    # the objects in the context to work properly
    Negotiator.send(:prepend, Surrounded)
  end
end