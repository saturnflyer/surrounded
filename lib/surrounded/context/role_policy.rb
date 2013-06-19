module Surrounded
  module Context

    class RolePolicy

      class NotImplementedError < StandardError; end

      attr_reader :context, :map
      private :context, :map

      def initialize(context, map)
        @context, @map = context, map
      end

      def call(context_method_name, applicator)
        apply_policy(applicator) if applicable?(context_method_name)
      end

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