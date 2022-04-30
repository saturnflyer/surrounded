module Surrounded
  module Context
    module Seclusion
      # Set a named constant and make it private
      def private_const_set(name, const)
        unless role_const_defined?(name)
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
    end
  end
end
