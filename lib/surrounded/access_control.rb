module Surrounded
  module AccessControl
    def self.extended(base)
      base.send(:include, AccessMethods)
      unless defined?(base::AccessError)
        base.const_set(:AccessError, Class.new(::Surrounded::Context::AccessError))
      end
    end
    
    private
    
    def disallow(*names, &block)
      names.map do |name|
        define_access_method(name, &block)
      end
    end
    alias_method :guard, :disallow
    
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
      num = __LINE__; mod.class_eval {
        define_method "disallow_#{name}?" do
          begin
            apply_behaviors
            instance_exec(&block)
          ensure
            remove_behaviors
          end
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
          method_restrictor = "disallow_#{name}?"
          !self.respond_to?(method_restrictor, true) || !self.send(method_restrictor)
        }.to_set
      end

      # Ask if the context will allow access to a trigger given the current players.
      def allow?(name)
        unless self.respond_to?(name)
          raise NoMethodError, %{undefined method `#{name}' for #{self.inspect}}
        end
        if self.respond_to?("disallow_#{name}?")
          !self.public_send("disallow_#{name}?")
        else
          true
        end
      end
    end
  end
end