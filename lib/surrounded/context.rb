module Surrounded
  module Context
    def setup(*setup_args)
      attr_reader *setup_args

      define_method(:initialize){ |*args|
        Hash[setup_args.zip(args)].each{ |key, value|
          role_mod_name = key.to_s.classify
          if self.class.const_defined?(role_mod_name)
            value = Surrounded::Context.modify(value, self.class.const_get(role_mod_name))
          end
          instance_variable_set("@#{key}", value)
        }
      }
    end

    def trigger(name, *args, &block)
      @triggers ||= []
      @triggers << name

      define_method(:"trigger_#{name}", *args, &block)

      private :"trigger_#{name}"

      define_method(name, *args){
        begin
          Thread.current[:context] ||= []
          Thread.current[:context].unshift(self)
          self.send("trigger_#{name}", *args)
        ensure
          Thread.current[:context].shift
        end
      }
    end

    def triggers
      @triggers.dup
    end

    private

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