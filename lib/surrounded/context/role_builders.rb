module Surrounded
  module Context
    class InvalidRoleType < ::StandardError; end

    module RoleBuilders
      extend Seclusion

      def self.extended(base)
        Surrounded::Exceptions.define(base, exceptions: :InvalidRoleType)
      end

      # Define behaviors for your role players
      def role(name, type = default_role_type, &block)
        if type == :module
          mod_name = RoleName(name)
          mod = Module.new(&block).send(:include, ::Surrounded)
          private_const_set(mod_name, mod)
        else
          meth = method(type)
          meth.call(name, &block)
        end
      rescue NameError => e
        raise self::InvalidRoleType, e.message
      end
      alias_method :role_methods, :role

      # Create a named behavior for a role using the standard library SimpleDelegator.
      def wrap(name, &block)
        require "delegate"
        wrapper_name = RoleName(name)
        klass = private_const_set(wrapper_name, Class.new(SimpleDelegator, &block))
        klass.send(:include, Surrounded)
      end
      alias_method :wrapper, :wrap

      # Create a named behavior for a role using the standard library DelegateClass.
      # This ties the implementation of the role to a specific class or module API.
      def delegate_class(name, class_name, &block)
        require "delegate"
        wrapper_name = RoleName(name)
        klass = private_const_set(wrapper_name, DelegateClass(Object.const_get(class_name.to_s)))
        klass.class_eval(&block)
        klass.send(:include, Surrounded)
      end

      # Create an object which will bind methods to the role player.
      #
      # This object will behave differently that a wrapper or delegate_class.
      # The interface object should only be used for objects whose methods
      # _will not_ call to the other objects in the context.
      # Because the interface methods are applied individually to an object,
      # that object is unaware of the other objects in the context and cannot
      # access them from any of its methods.
      def interface(name, &block)
        # AdminInterface
        interface_name = RoleName(name, "Interface")
        behavior = private_const_set(interface_name, Module.new(&block))

        require "surrounded/context/negotiator"
        # Admin
        private_const_set(RoleName(name), Negotiator.for_role(behavior))
      end

      private

      def RoleName(text, suffix = nil)
        RoleName.new(text, suffix)
      end
    end
  end
end
