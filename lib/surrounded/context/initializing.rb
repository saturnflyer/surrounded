module Surrounded
  module Context
    module Initializing
      # Shorthand for creating an instance level initialize method which
      # handles the mapping of the given arguments to their named role.
      def initialize(*setup_args)
        private_attr_reader(*setup_args)
      
        mod = Module.new
        line = __LINE__
        mod.class_eval "
          def initialize(#{setup_args.join(',')})
            arguments = method(__method__).parameters.map{|arg| eval(arg[1].to_s) }
            @role_map = RoleMap.new
            map_roles(#{setup_args}.zip(arguments))
          end
        ", __FILE__, line
        const_set("ContextInitializer", mod)
        include mod
      end
    end
  end
end