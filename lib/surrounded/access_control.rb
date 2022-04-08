module Surrounded
  module Context
    class AccessError < ::StandardError; end
  end
  module AccessControl
    def self.extended(base)
      base.send(:include, AccessMethods)
      Surrounded::Exceptions.define(base, exceptions: :AccessError)
    end
    
    private
    
    def disallow(*names, &block)
      names.map do |name|
        define_access_method(name, &block)
      end
    end
    alias guard disallow
    
    def trigger_return_content(name, *args, &block)
      %{

        method_restrictor = "disallow_#{name}?"
        if self.respond_to?(method_restrictor, true) && self.send(method_restrictor)
          raise ::#{self.to_s}::AccessError.new("access to #{self.name}##{name} is not allowed")
        end

      #{super}
      }
    end
    
    def define_access_method(name, &block)
      mod = Module.new
      mod.class_eval {
        define_method "disallow_#{name}?" do
          apply_behaviors
          instance_exec(&block)
        ensure
          remove_behaviors
        end
      }
      const_set("SurroundedAccess#{name}", mod)
      include mod
    end
    
    module AccessMethods
      # Return a Set of all defined triggers regardless of any disallow blocks
      def all_triggers
        self.class.triggers
      end
    
      # Return a Set of triggers which may be run according to any restrictions defined
      # in disallow blocks.
      def triggers
        all_triggers.select {|name|
          allow?(name)
        }.to_set
      end

      # Ask if the context will allow access to a trigger given the current players.
      def allow?(name)
        raise NoMethodError, %{undefined method `#{name}' for #{self.inspect}} unless self.respond_to?(name)
        predicate = "disallow_#{name}?"
        !self.respond_to?(predicate) || !self.public_send(predicate)
      end
    end
  end
end
