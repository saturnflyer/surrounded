module Surrounded
  module Context
    class Negotiator
      class << self
        # Return a class which has methods defined to forward the method to
        # the wrapped object delegating to the behavior module.
        # This prevents hits to method_missing.
        def for_role(mod)
          klass = Class.new(self)
          # Define access to the provided module
          klass.send(:define_method, :__behaviors__) do
            mod
          end
          # For each method in the module, directly forward to the wrapped object to
          # circumvent method_missing
          mod.instance_methods(false).each do |meth|
            num = __LINE__; klass.class_eval %{
              def #{meth}(...)
                @#{meth}_method ||= __behaviors__.instance_method(:#{meth}).bind(@object)
                @#{meth}_method.call(...)
              end
            }, __FILE__, num
          end
          klass
        end
      end


      identity = %w[__send__ object_id equal?]
      method_access = %w[respond_to? method __behaviors__]

      reserved_methods = (identity + method_access).join('|')

      # Remove all methods except the reserved methods
      instance_methods.reject{ |m|
        m.to_s =~ /#{reserved_methods}/
      }.each do |meth|
        undef_method meth
      end

      include Surrounded

      private

      # Store the context in the wrapped object if it can do so
      def store_context(&block)
        if @object.respond_to?(__method__, true)
          @object.send(__method__, &block)
        else
          super
        end
        self
      end
      # These only differ in the message they send
      alias remove_context store_context

      def initialize(object)
        @object = object
      end

      def method_missing(meth, ...)
        @object.send(meth, ...)
      end

      def respond_to_missing?(meth, include_private=false)
        @object.respond_to?(meth, include_private)
      end
    end
  end
end
