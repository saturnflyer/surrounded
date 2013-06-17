module Surrounded
  module Context

    class RolePolicy

      class NotImplementedError < StandardError; end

      attr_reader :context, :assignments
      private :context, :assignments

      def initialize(context, assignments)
        @context, @assignments = context, assignments
      end

      def call(context_method_name, applicator)
        apply_policy(applicator) if applicable?(context_method_name)
      end

      def apply_policy(applicator)
        assignments.each do |name, object|
          role_module_name = role_constant_name(name)

          if context.class.const_defined?(role_module_name)
            assignments[name] = applicator.call(object, context.class.const_get(role_module_name))
          end
        end
      end

      def role_constant_name(string)
        string.to_s.gsub(/(?:^|_)([a-z])/) { $1.upcase }
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