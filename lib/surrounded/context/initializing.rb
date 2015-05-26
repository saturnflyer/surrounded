module Surrounded
  module Context
    module Initializing
      # Shorthand for creating an instance level initialize method which
      # handles the mapping of the given arguments to their named role.
      def initialize_without_keywords(*setup_args)
        private_attr_reader(*setup_args)
      
        mod = Module.new
        line = __LINE__; mod.class_eval "
          def initialize(#{setup_args.join(',')})
            @role_map = role_mapper_class.new
            map_roles(#{setup_args.to_s}.zip([#{setup_args.join(',')}]))
          end
        ", __FILE__, line
        const_set("ContextInitializer", mod)
        include mod
      end
      def initialize(*setup_args)
        warn "Deprecated: The behavior of 'initialize' will require keywords in the future
            Consider using keyword arguments or switching to 'initialize_without_keywords'\n\n"
        initialize_without_keywords(*setup_args)
      end

      def keyword_initialize(*setup_args)
        private_attr_reader(*setup_args)

        parameters = setup_args.map{|a| "#{a}:"}.join(',')

        mod = Module.new
        line = __LINE__; mod.class_eval %{
          def initialize(#{parameters})
            @role_map = role_mapper_class.new
            map_roles(#{setup_args.to_s}.zip([#{setup_args.join(',')}]))
          end
        }, __FILE__, line
        const_set("ContextInitializer", mod)
        include mod
      end
      alias initialize_with_keywords keyword_initialize
    end
  end
end