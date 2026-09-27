module Surrounded
  module Visualization
    # Reads the behavior a context defines for a role and tells a listener.
    class Behavior
      # @param context_class [Class] a class extended with Surrounded::Context
      # @param role [Symbol] the role
      # @param constant_name [#to_s] the name of the constant holding the behavior
      def initialize(context_class, role, constant_name = Surrounded::Context::RoleName.new(role))
        @context_class = context_class
        @role = role
        @constant_name = constant_name.to_s
      end

      # @param listener [#role]
      # @return [self]
      def tell(listener)
        listener.role(name: @role, type: type, methods: role_methods, behavior: holder)
        self
      end

      private

      def constant
        return @constant if defined?(@constant)

        @constant = constant_named(@constant_name)
      end

      def constant_named(name)
        @context_class.const_get(name, false) if @context_class.const_defined?(name, false)
      rescue NameError
        nil
      end

      def negotiator?
        defined?(Surrounded::Context::Negotiator) &&
          constant.is_a?(Class) &&
          constant < Surrounded::Context::Negotiator
      end

      # An interface keeps its methods in a module beside the role constant.
      def holder
        return @holder if defined?(@holder)

        @holder = (negotiator? && constant_named("#{@constant_name}Interface")) || constant
      end

      def type
        if constant.nil?
          nil
        elsif negotiator?
          :interface
        elsif !constant.is_a?(Class)
          :module
        elsif defined?(::SimpleDelegator) && constant < ::SimpleDelegator
          :wrap
        elsif defined?(::Delegator) && constant < ::Delegator
          :delegate_class
        else
          :class
        end
      end

      def role_methods
        return [] unless holder

        own_methods.reject { |name| forwarding?(holder.instance_method(name)) }.sort
      end

      # The methods defined in the behavior itself. A class made by
      # DelegateClass answers instance_methods with the methods of the class
      # it wraps as well as its own, so Module is asked in its place.
      def own_methods
        ::Module.instance_method(:instance_methods).bind_call(holder, false)
      end

      # DelegateClass defines methods to forward to the object it wraps.
      # Those are not role methods.
      def forwarding?(method)
        return false unless type == :delegate_class

        method.source_location&.first == delegate_library
      end

      def delegate_library
        ::Delegator.instance_method(:method_missing).source_location&.first
      end
    end
  end
end
