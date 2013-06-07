require 'set'
module Surrounded
  module Context
    def setup(*setup_args)
      attr_reader *setup_args

      define_method(:initialize){ |*args|
        Hash[setup_args.zip(args)].each{ |role, object|

          role_module_name = Context.classify_string(role)
          klass = self.class

          if klass.const_defined?(role_module_name)
            object = Context.modify(object, klass.const_get(role_module_name))
          end

          instance_variable_set("@#{role}", object)
        }
      }
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

    def triggers
      @triggers.dup
    end

    private

    def store_trigger(name)
      @triggers ||= Set.new
      @triggers << name
    end

    def self.classify_string(string)
      string.to_s.gsub(/(?:^|_)([a-z])/) { $1.upcase }
    end

    def self.modify(obj, mod)
      if obj.respond_to?(:cast_as)
        obj.cast_as(mod)
      else
        obj.extend(mod)
      end
    end
  end
end