module Surrounded
  module Context
    module Initializing
      extend Seclusion

      # Shorthand for creating an instance level initialize method which
      # handles the mapping of the given arguments to their named role.
      def initialize_without_keywords(*setup_args, &block)
        parameters = setup_args.join(",")
        default_initializer(parameters, setup_args, &block)
      end

      def initialize(*setup_args, &block)
        parameters = setup_args.map { |a| "#{a}:" }.join(",")
        default_initializer(parameters, setup_args, &block)
      end
      alias_method :keyword_initialize, :initialize
      alias_method :initialize_with_keywords, :keyword_initialize

      def initializer_block
        @initializer_block
      end

      def apply_initializer_block(instance)
        instance.instance_eval(&initializer_block) if initializer_block
      end

      def default_initializer(params, setup_args, &block)
        private_attr_reader(*setup_args)
        @initializer_block = block
        mod = Module.new
        line = __LINE__; mod.class_eval %{
          def initialize(#{params})
            @role_map = role_mapper_class.new
            @initializer_arguments = Hash[#{setup_args}.zip([#{setup_args.join(",")}])]
            map_roles(@initializer_arguments)
            self.class.apply_initializer_block(self)
          end
        }, __FILE__, line
        const_set(:ContextInitializer, mod)
        include mod

        private_attr_reader :initializer_arguments
      end
    end
  end
end
