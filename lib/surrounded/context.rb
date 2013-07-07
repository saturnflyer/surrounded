require 'set'
require 'surrounded/context/role_map'
require 'surrounded/context/role_policy'
module Surrounded
  module Context
    def self.extended(base)
      base.send(:include, InstanceMethods)
      base.singleton_class.send(:alias_method, :setup, :initialize)
    end

    def new_policy(context, assignments)
      policy.new(context, assignments)
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
      #     policy.call(__method__, method(:add_role_interface))
      #   end
      # >

      define_method(:initialize){ |*args|

        role_object_array = setup_args.zip(args)

        map_roles(role_object_array)

        policy.call(__method__, method(:add_role_interface))
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
          store_context
          policy.call(__method__, method(:add_role_interface))

          self.send("trigger_#{name}", *args)

        ensure
          policy.call(__method__, method(:remove_role_interface))
          remove_context
        end
      }
    end

    def store_trigger(name)
      @triggers ||= Set.new
      @triggers << name
    end

    module InstanceMethods
      def role?(name, &block)
        if role_map.role?(name)
          accessor = eval('self', block.binding)
          role_map.role_player?(accessor) && role_map.assigned_player(name)
        else
          false
        end
      rescue Surrounded::Context::InvalidRole
        false
      end

      def triggers
        self.class.triggers
      end

      def role_players
        @role_players.dup
      end

      private

      def store_role_player(player)
        @role_players ||= Set.new
        @role_players << player
      end

      def role_map
        @role_map ||= RoleMap.new
      end

      def map_roles(role_object_array)
        role_object_array.each do |role, object|
          store_role_player(object)
          instance_variable_set("@#{role}", object)
          role_map << [role, role_behavior(role), object]
        end
      end

      def policy
        @policy ||= self.class.new_policy(self, role_map)
      end

      def add_role_interface(obj, mod)
        modifier = modifier_methods.find do |meth|
                     obj.respond_to?(meth)
                   end || :extend
        return obj if mod.is_a?(Class) || !modifier

        obj.send(modifier, mod)
        obj
      end

      def remove_role_interface(obj, mod)
        obj.uncast if obj.respond_to?(:uncast)
        obj
      end

      def modifier_methods
        [:cast_as]
      end

      def role_behavior(role)
        role.to_s.gsub(/(?:^|_)([a-z])/) { $1.upcase }
      end

      def store_context
        @role_players.each do |player|
          player.store_context(self)
        end
      end

      def remove_context
        @role_players.each do |player|
          player.remove_context
        end
      end
    end
  end
end