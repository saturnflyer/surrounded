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
      #     policy.call(__method__, method(:add_role_methods))
      #   end
      # >

      define_method(:initialize){ |*args|
        setup_args.zip(args).each{ |role, object|
          assign_role(role, object)
        }
        policy.call(__method__, method(:add_role_methods))
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
          Thread.current[:context].unshift(self)
          policy.call(__method__, method(:add_role_methods))

          self.send("trigger_#{name}", *args)

        ensure
          policy.call(__method__, method(:remove_role_methods))
          Thread.current[:context].shift
        end
      }
    end

    def store_trigger(name)
      @triggers ||= Set.new
      @triggers << name
    end

    module InstanceMethods
      def role?(name, &block)
        accessor = eval('self', block.binding)
        role_map.role_player?(accessor) && role_map.assigned_player(name)
      rescue Surrounded::Context::InvalidRole
        false
      end

      def triggers
        self.class.triggers
      end

      private

      def role_map
        @role_map ||= RoleMap.new
      end

      def policy
        @policy ||= self.class.new_policy(self, role_map)
      end

      def add_role_methods(obj, mod)
        modifier = modifier_methods.find do |meth|
                     obj.respond_to?(meth)
                   end
        return obj if mod.is_a?(Class) || !modifier

        obj.send(modifier, mod)
        obj
      end

      def remove_role_methods(obj, mod)
        obj.uncast if obj.respond_to?(:uncast)
        obj
      end

      def modifier_methods
        [:cast_as, :extend]
      end

      def assign_role(role, obj)
        role_map << [role, role_behavior(role), obj]
        instance_variable_set("@#{role}", obj)
        self
      end

      def role_behavior(role)
        role.to_s.gsub(/(?:^|_)([a-z])/) { $1.upcase }
      end
    end
  end
end