# Some features are only available in versions of Ruby
# where this method is true
unless defined?(module_method_rebinding?)
  def module_method_rebinding?
    return @__module_method_rebinding__ if defined?(@__module_method_rebinding__)
    sample_method = Enumerable.instance_method(:to_a)
    @__module_method_rebinding__ = begin
      !!sample_method.bind(Object.new)
    rescue TypeError
      false
    end
  end
end

module Surrounded
  module Context
    module RoleBuilders

      # Define behaviors for your role players
      def role(name, type=nil, &block)
        role_type = type || default_role_type
        if role_type == :module
          mod_name = name.to_s.gsub(/(?:^|_)([a-z])/){ $1.upcase }
          mod = Module.new(&block)
          mod.send(:include, ::Surrounded)
          private_const_set(mod_name, mod)
        else
          meth = method(role_type)
          meth.call(name, &block)
        end
      rescue NameError => e
        raise e.extend(InvalidRoleType)
      end
      alias_method :role_methods, :role

      # Create a named behavior for a role using the standard library SimpleDelegator.
      def wrap(name, &block)
        require 'delegate'
        wrapper_name = name.to_s.gsub(/(?:^|_)([a-z])/){ $1.upcase }
        klass = private_const_set(wrapper_name, Class.new(SimpleDelegator, &block))
        klass.send(:include, Surrounded)
      end
      alias_method :wrapper, :wrap


      if module_method_rebinding?
        # Create an object which will bind methods to the role player
        def interface(name, &block)
          class_basename = name.to_s.gsub(/(?:^|_)([a-z])/){ $1.upcase }
          interface_name = class_basename + 'Interface'

          behavior = private_const_set(interface_name, Module.new(&block))

          require 'surrounded/context/negotiator'
          undef_method(name)
          define_method(name) do
            instance_variable_set("@#{name}", Negotiator.new(role_map.assigned_player(name), behavior))
          end
        end
      end
      
    end
  end
end