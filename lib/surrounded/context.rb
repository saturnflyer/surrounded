require 'set'
require 'surrounded/exceptions'
require 'surrounded/context/role_map'
require 'surrounded/context/seclusion'
require 'surrounded/context/role_builders'
require 'surrounded/context/initializing'
require 'surrounded/context/forwarding'
require 'surrounded/context/trigger_controls'
require 'surrounded/access_control'
require 'surrounded/shortcuts'
require 'surrounded/east_oriented'
require 'surrounded/context/name_collision_detector'

# Extend your classes with Surrounded::Context to handle their
# initialization and application of behaviors to the role players
# passed into the constructor.
#
# The purpose of this module is to help you create context objects
# which encapsulate the interaction and behavior of objects inside.
module Surrounded
  module Context
    def self.extended(base)
      base.class_eval {
        extend Seclusion, RoleBuilders, Initializing, Forwarding, NameCollisionDetector

        @triggers = Set.new
        include InstanceMethods

        trigger_mod = Module.new
        const_set('TriggerMethods', trigger_mod)
        include trigger_mod

        extend TriggerControls

      }
    end

    # Set the default type of implementation for role methods for all contexts.
    def self.default_role_type
      @default_role_type ||= :module
    end

    class << self
      attr_writer :default_role_type
    end

    private

    def default_role_type
      @default_role_type ||= Surrounded::Context.default_role_type
    end

    # Set the default type of implementation for role method for an individual context.
    def default_role_type=(type)
      @default_role_type = type
    end

    # Provide the ability to create access control methods for your triggers.
    def protect_triggers;  self.extend(::Surrounded::AccessControl); end

    # Automatically create class methods for each trigger method.
    def shortcut_triggers; self.extend(::Surrounded::Shortcuts); end

    # Automatically return the context object from trigger methods.
    def east_oriented_triggers; self.extend(::Surrounded::EastOriented); end

    # === Utility shortcuts

    def role_const_defined?(name)
      const_defined?(name, false)
    end

    # Conditional const_get for a named role behavior
    def role_const(name)
      if role_const_defined?(name)
        const_get(name)
      end
    end

    # Allow alternative implementations for the role map
    # This requires that the specified mapper klass have an
    # initializer method called 'from_base' which accepts a
    # class name used to initialize the base object
    def role_mapper_class(mapper: RoleMap, base: ::Triad)
      @role_mapper_class ||= mapper.from_base(base)
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

      # Reuse the same context object but pass new values
      def rebind(**options_hash)
        clear_instance_variables
        begin
          initialize(**options_hash)
        rescue ArgumentError
          initialize(*options_hash.values)
        end
        self
      end

      private

      def clear_instance_variables
        instance_variables.each{|ivar| remove_instance_variable(ivar) }
      end

      def role_map
        @role_map ||= role_mapper_class.new
      end

      def map_roles(role_object_array)
        detect_collisions role_object_array
        role_object_array.to_a.each do |role, object|
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

      def apply_behavior(role, behavior, object)
        if behavior && role_const_defined?(behavior)
          applicator = if self.respond_to?("apply_behavior_#{role}")
                          method("apply_behavior_#{role}")
                        elsif role_const(behavior).is_a?(Class)
                          method(:apply_class_behavior)
                        else
                          method(:apply_module_behavior)
                        end

          role_player = applicator.call(role_const(behavior), object)
          map_role(role, behavior, role_player)
        end
        role_player || object
      end

      def apply_module_behavior(mod, obj)
        adder_name = module_extension_methods.find{|meth| obj.respond_to?(meth) }
        return obj unless adder_name

        obj.method(adder_name).call(mod)
        obj
      end

      def apply_class_behavior(klass, obj)
        wrapper_name = wrap_methods.find{|meth| klass.respond_to?(meth) }
        return obj if !wrapper_name
        klass.method(wrapper_name).call(obj)
      end

      def remove_behavior(role, behavior, object)
        if behavior && role_const_defined?(behavior)
          remover_name = (module_removal_methods + unwrap_methods).find do |meth|
            object.respond_to?(meth)
          end
        end

        role_player = if self.respond_to?("remove_behavior_#{role}")
                        self.send("remove_behavior_#{role}", role_const(behavior), object)
                      elsif remover_name
                        object.send(remover_name)
                      end

        role_player || object
      end

      def apply_behaviors
        role_map.each do |role, mod_name, object|
          player = apply_behavior(role, mod_name, object)
          if player.respond_to?(:store_context, true)
            player.__send__(:store_context) do; end
          end
        end
      end

      def remove_behaviors
        role_map.each do |role, mod_name, player|
          if player.respond_to?(:remove_context, true)
            player.__send__(:remove_context) do; end
          end
          remove_behavior(role, mod_name, player)
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
        RoleName.new(role)
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

      def role_mapper_class
        self.class.send(:role_mapper_class)
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

    class RoleName
      def initialize(string, suffix=nil)
        @string = string.
                    to_s.
                    split(/_/).
                    map{|part|
                      part.capitalize
                    }.
                    join.
                    sub(/_\d+/,'') + suffix.to_s
      end

      def to_str
        @string
      end
      alias to_s to_str

      def to_sym
        @string.to_sym
      end
    end
  end
end
