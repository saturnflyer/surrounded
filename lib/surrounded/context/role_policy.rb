module Surrounded
  module Context

    class RolePolicy

      class NotImplementedError < StandardError; end

      attr_reader :context, :map, :role_adder, :role_remover
      private :context, :map, :role_adder, :role_remover

      def initialize(context, map, role_adder, role_remover)
        @context, @map, @role_adder, @role_remover = context, map, role_adder, role_remover
      end

      def apply_roles(context_method_name)
        apply_policy(role_adder) if applicable?(context_method_name)
      end

      def remove_roles(context_method_name)
        apply_policy(role_remover) if applicable?(context_method_name)
      end

      private

      def apply_policy(applicator)
        map.each do |role, mod_name, _|
          if context.class.const_defined?(mod_name)
            applicator.call(map.assigned_player(role), context.class.const_get(mod_name))
          end
        end
      end
    end

    class InitializePolicy < RolePolicy
      def applicable?(method_name)
        method_name.to_s == 'initialize'
      end
    end

    class TriggerPolicy < RolePolicy
      def applicable?(method_name)
        context.triggers.include?(method_name)
      end
    end

  end
end