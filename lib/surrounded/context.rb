require 'set'
require 'surrounded/context/role_map'
require 'surrounded/context/role_builders'
require 'surrounded/context/initializing'
require 'surrounded/access_control'
require 'surrounded/shortcuts'
require 'surrounded/east_oriented'

# Extend your classes with Surrounded::Context to handle their
# initialization and application of behaviors to the role players
# passed into the constructor.
#
# The purpose of this module is to help you create context objects
# which encapsulate the interaction and behavior of objects inside.
module Surrounded
  module Context
    def self.extended(base)
      base.extend RoleBuilders, Initializing
      base.class_eval {
        @triggers = Set.new
        include InstanceMethods
      }
    end

    # Provides a Set of all available trigger methods where
    # behaviors will be applied to the roles before execution
    # and removed afterward.
    def triggers
      @triggers.dup
    end

    private

    # Set the default type of implementation for role methods for all contexts.
    def self.default_role_type
      @default_role_type ||= :module
    end

    class << self
      attr_writer :default_role_type
    end
    
    # Provide the ability to create access control methods for your triggers.
    def protect_triggers;  self.extend(::Surrounded::AccessControl); end
    
    # Automatically create class methods for each trigger method.
    def shortcut_triggers; self.extend(::Surrounded::Shortcuts); end
    
    # Automatically return the context object from trigger methods.
    def east_oriented_triggers; self.extend(::Surrounded::EastOriented); end

    def default_role_type
      @default_role_type ||= Surrounded::Context.default_role_type
    end

    # Set the default type of implementation for role method for an individual context.
    def default_role_type=(type)
      @default_role_type = type
    end

    # Set the time to apply roles to objects. Either :trigger or :initialize. 
    # Defaults to :trigger
    def apply_roles_on(which)
      @__apply_role_policy = which
    end

    def __apply_role_policy
      @__apply_role_policy ||= :trigger
    end

    # Creates a context instance method which will apply behaviors to role players
    # before execution and remove the behaviors after execution.
    #
    # Alternatively you may define your own methods then declare them as triggers
    # afterward.
    # 
    # Example:
    #   trigger :some_event do
    #     # code here
    #   end
    #
    #   def some_event
    #     # code here
    #   end
    #   trigger :some_event
    #
    def trigger(*names, &block)
      if block.nil?
        names.each do |name|
          convert_method_to_trigger(name)
        end
      else
        name = names.first
        define_method(name, &block)
        convert_method_to_trigger(name)
      end
    end

    def store_trigger(*names)
      @triggers.merge(names)
    end
    
    def convert_method_to_trigger(name)
      unless triggers.include?(name) || name.nil?
        alias_method :"__trigger_#{name}", :"#{name}"
        private :"__trigger_#{name}"
        remove_method :"#{name}"
        define_trigger_wrap_method(name)
        store_trigger(name)
      end
    end

    def define_trigger_wrap_method(name)
      mod = Module.new
      line = __LINE__
      mod.class_eval %{
        def #{name}(*args, &block)
          begin
            apply_roles if __apply_role_policy == :trigger

            #{trigger_return_content(name)}

          ensure
            remove_roles if __apply_role_policy == :trigger
          end
        end
      }, __FILE__, line
      const_set("SurroundedTrigger#{name.to_s.upcase.sub(/\?\z/,'Query')}", mod)
      include mod
    end
    
    def trigger_return_content(name, *args, &block)
      %{self.send("__trigger_#{name}", *args, &block)}
    end
    
    # === Utility shortcuts
    
    # Set a named constant and make it private
    def private_const_set(name, const)
      unless self.const_defined?(name, false)
        const = const_set(name, const)
        private_constant name.to_sym
      end
      const
    end

    # Create attr_reader for the named methods and make them private
    def private_attr_reader(*method_names)
      attr_reader(*method_names)
      private(*method_names)
    end

    # Conditional const_get for a named role behavior
    def role_const(name)
      if role_const_defined?(name)
        const_get(name)
      end
    end

    def role_const_defined?(name)
      const_defined?(name, false)
    end

    module InstanceMethods
      # Check whether a given name is a role inside the context.
      # The provided block is used to evaluate whether or not the caller
      # is allowed to inquire about the roles.
      def role?(name, &block)
        return false unless role_map.role?(name)
        accessor = block.binding.eval('self')
        role_map.role_player?(accessor) && role_map.assigned_player(name)
      end

      # Check if a given object is a role player in the context.
      def role_player?(obj)
        role_map.role_player?(obj)
      end

      # Return a Set of all defined triggers
      def triggers
        self.class.triggers
      end

      private

      def preinitialize
        @__apply_role_policy = self.class.send(:__apply_role_policy)
      end

      def postinitialize
        apply_roles if __apply_role_policy == :initialize
      end

      def role_map
        @role_map ||= RoleMap.new
      end

      def map_roles(role_object_array)
        role_object_array.each do |role, object|
          if self.respond_to?("map_role_#{role}")
            self.send("map_role_#{role}", object)
          else
            map_role(role, role_behavior_name(role), object)
            map_role_collection(role, role_behavior_name(role), object)
          end
        end
      end

      def map_role_collection(role, mod_name, collection)
        singular_role_name = singularize_name(role)
        singular_behavior_name = singularize_name(role_behavior_name(role))
        if collection.respond_to?(:each_with_index) && role_const_defined?(singular_behavior_name)
          collection.each_with_index do |item, index|
            map_role(:"#{singular_role_name}_#{index + 1}", singular_behavior_name, item)
          end
        end
      end

      def map_role(role, mod_name, object)
        instance_variable_set("@#{role}", object)
        role_map.update(role, role_module_basename(mod_name), object)
      end

      def __apply_role_policy
        @__apply_role_policy
      end

      def add_interface(role, behavior, object)
        applicator = behavior.is_a?(Class) ? method(:add_class_interface) : method(:add_module_interface)

        role_player = applicator.call(object, behavior)
        map_role(role, behavior, role_player) if behavior
        role_player.send(:store_context, self){}
        role_player
      end

      def add_module_interface(obj, mod)
        adder_name = module_extension_methods.find{|meth| obj.respond_to?(meth) }
        return obj if !adder_name

        obj.method(adder_name).call(mod)
        obj
      end

      def add_class_interface(obj, klass)
        wrapper_name = wrap_methods.find{|meth| klass.respond_to?(meth) }
        return obj if !wrapper_name

        klass.method(wrapper_name).call(obj)
      end

      def remove_interface(role, behavior, object)
        remover_name = (module_removal_methods + unwrap_methods).find{|meth| object.respond_to?(meth) }
        object.send(:remove_context) do; end

        if remover_name
          role_player = object.send(remover_name)
        end

        return role_player || object
      end

      def apply_roles
        traverse_map method(:add_interface)
      end

      def remove_roles
        traverse_map method(:remove_interface)
      end

      def traverse_map(applicator)
        role_map.each do |role, mod_name, object|
          if role_const_defined?(mod_name)
            applicator.call(role, role_const(mod_name), object)
          end
        end
      end

      # List of possible methods to use to add behavior to an object from a module.
      def module_extension_methods
        [:cast_as, :extend]
      end

      # List of possible methods to use to add behavior to an object from a wrapper.
      def wrap_methods
        [:new]
      end

      # List of possible methods to use to remove behavior from an object with a module.
      def module_removal_methods
        [:uncast]
      end

      # List of possible methods to use to remove behavior from an object with a wrapper.
      def unwrap_methods
        [:__getobj__]
      end

      def role_behavior_name(role)
        role.to_s.gsub(/(?:^|_)([a-z])/) { $1.upcase }.sub(/_\d+/,'')
      end

      def role_module_basename(mod)
        mod.to_s.split('::').last
      end

      def role_const(name)
        self.class.send(:role_const, name)
      end

      def role_const_defined?(name)
        self.class.send(:role_const_defined?, name)
      end

      def singularize_name(name)
        if name.respond_to?(:singularize)
          name.singularize
        else
          # good enough for now but should be updated with better rules
          name.to_s.tap do |string|
            if string =~ /ies\z/
              string.sub!(/ies\z/,'y')
            elsif string =~ /s\z/
              string.sub!(/s\z/,'')
            end
          end
        end
      end
    end
  end
end