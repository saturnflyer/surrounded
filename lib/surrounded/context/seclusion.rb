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

      # Create readers for the named methods and make them private. Role names
      # resolve to the current player (original object, or its applied wrapper
      # during a trigger); any other name reads its instance variable.
      def private_attr_reader(*method_names)
        method_names.each do |name|
          define_method(name) do
            role_map.role?(name) ? role_map.current_player(name) : instance_variable_get(:"@#{name}")
          end
          private(name)
        end
      end
    end
  end
end
