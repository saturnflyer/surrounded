require 'set'
require 'surrounded/context/role_map'
require 'surrounded/context/role_policy'
module Surrounded
  module Context
    def self.extended(base)
      base.send(:include, InstanceMethods)
      base.singleton_class.send(:alias_method, :setup, :initialize)
    end

    def new_policy(context, assignments, add_method, remove_method)
      policy.new(context, assignments, add_method, remove_method)
    end

    def triggers
      @triggers.dup
    end

    private

    def policies
      @policies ||= {
        'initialize' => Surrounded::Context::InitializePolicy,
        'trigger' => Surrounded::Context::TriggerPolicy
      }
    end

    def apply_roles_on(which)
      @policy = policies.fetch(which.to_s){ const_get(which) }
    end

    def policy
      @policy ||= apply_roles_on(:trigger)
    end

    def initialize(*setup_args)
      private_attr_reader(*setup_args)

      # I want this to work so I can set the arity on initialize:
      # class_eval %Q<
      #   def initialize(#{*setup_args})
      #     arguments = parameters.map{|arg| eval(arg[1].to_s) }
      #     variable_names = Array(#{*setup_args})
      #     variable_names.zip(arguments).each do |role, object|
      #       assign_role(role, object)
      #     end
      #     policy.call(__method__, method(:add_interface))
      #   end
      # >

      define_method(:initialize){ |*args|

        role_object_array = setup_args.zip(args)

        map_roles(role_object_array)

        policy.apply_roles(__method__)
      }
    end

    def private_attr_reader(*method_names)
      attr_reader(*method_names)
      private(*method_names)
    end

    def trigger(name, *args, &block)
      store_trigger(name)

      define_method(:"trigger_#{name}", *args, &block)

      private :"trigger_#{name}"

      define_method(name, *args){
        begin
          policy.apply_roles(__method__)

          self.send("trigger_#{name}", *args)

        ensure
          policy.remove_roles(__method__)
        end
      }
    end

    def store_trigger(name)
      @triggers ||= Set.new
      @triggers << name
    end

    module InstanceMethods
      def role?(name, &block)
        return false unless role_map.role?(name)
        accessor = eval('self', block.binding)
        role_map.role_player?(accessor) && role_map.assigned_player(name)
      end

      def triggers
        self.class.triggers
      end

      private

      def modified_players
        @modified_players ||= Set.new
      end

      def store_role_player(player)
        modified_players << player
      end

      def role_map
        @role_map ||= RoleMap.new
      end

      def map_roles(role_object_array)
        role_object_array.each do |role, object|
          instance_variable_set("@#{role}", object)
          role_map << [role, role_behavior_name(role), object]
        end
      end

      def policy
        @policy ||= self.class.new_policy(self, role_map, method(:add_interface), method(:remove_interface))
      end

      def add_interface(obj, behavior)
        applicator = behavior.is_a?(Class) ? method(:add_class_interface) : method(:add_module_interface)

        role_player = applicator.call(obj, behavior)
        store_role_player(role_player)

        role_player.store_context(self)
        role_player
      end

      def add_module_interface(obj, mod)
        adder_name = module_extension_methods.find do |meth|
                       obj.respond_to?(meth)
                     end
        modifier = adder_name && obj.method(adder_name)

        return obj if !modifier
        modifier.call(mod)
        obj
      end

      def add_class_interface(obj, klass)
        obj
      end

      def remove_interface(obj, behavior)
        applicator = behavior.is_a?(Class) ? method(:remove_class_interface) : method(:remove_module_interface)

        role_player = applicator.call(obj, behavior)

        role_player.remove_context
        role_player
      end

      def remove_module_interface(obj, mod)
        remover_name = module_removal_methods.find do |meth|
                       obj.respond_to?(meth)
                     end
        remover = remover_name && obj.method(remover_name)

        return obj if !remover
        remover.call
        obj
      end

      def remove_class_interface(obj, klass)
        remover = class_removal_methods.find do |meth|
                    obj.respond_to?(meth) && obj.method(meth)
                  end
        return obj if !remover
        remover.call
        obj
      end

      def module_extension_methods
        [:cast_as, :extend]
      end

      def class_extension_methods
        [:new]
      end

      def module_removal_methods
        [:uncast]
      end

      def class_removal_methods
        [:__getobj__]
      end

      def role_behavior_name(role)
        role.to_s.gsub(/(?:^|_)([a-z])/) { $1.upcase }.sub(/_\d+/,'')
      end
    end
  end
end