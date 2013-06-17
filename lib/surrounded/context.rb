require 'set'
module Surrounded
  module Context
    def self.extended(base)
      base.send(:include, InstanceMethods)
    end

    def triggers
      @triggers.dup
    end

    private

    def setup(*setup_args)
      private_attr_reader(*setup_args)

      define_method(:initialize){ |*args|
        setup_args.zip(args).each{ |role, object|

          role_module_name = Context.classify_string(role)

          if self.class.const_defined?(role_module_name)
            object = Context.modify(object, self.class.const_get(role_module_name))
          end

          set_role_attr(role, object)
        }
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
          (Thread.current[:context] ||= []).unshift(self)
          self.send("trigger_#{name}", *args)
        ensure
          (Thread.current[:context] ||= []).shift
        end
      }
    end

    def store_trigger(name)
      @triggers ||= Set.new
      @triggers << name
    end

    def self.classify_string(string)
      string.to_s.gsub(/(?:^|_)([a-z])/) { $1.upcase }
    end

    def self.modify(obj, mod)
      modifier = modifier_methods.find do |meth|
                   obj.respond_to?(meth)
                 end
      return obj if mod.is_a?(Class) || !modifier

      obj.send(modifier, mod)
    end

    def self.modifier_methods
      [:cast_as, :extend]
    end

    module InstanceMethods
      def role?(name, &block)
        accessor = eval('self', block.binding)
        roles.values.include?(accessor) && roles[name.to_s]
      end

      def triggers
        self.class.triggers
      end

      private

      def set_role_attr(role, obj)
        roles[role.to_s] = obj
        instance_variable_set("@#{role}", obj)
        self
      end

      def roles
        @roles ||= {}
      end
    end
  end
end