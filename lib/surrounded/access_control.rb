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
    
    def trigger_return_content(name)
      %{

        method_restrictor = "disallow_#{name}?"
        if self.respond_to?(method_restrictor, true) && self.send(method_restrictor)
          raise ::#{self.to_s}::AccessError.new("access to #{self.name}##{name} is not allowed")
        end

      #{super}
      }
    end
    
    def define_access_method(name, &block)
      class_eval {
        define_method "disallow_#{name}?" do
          begin
            apply_roles if __apply_role_policy == :trigger
            instance_exec(&block)
          ensure
            remove_roles if __apply_role_policy == :trigger
          end
        end
      }
    end
    
    module AccessMethods
      def all_triggers
        self.class.triggers
      end
    
      def triggers
        all_triggers.select {|name|
          method_restrictor = "disallow_#{name}?"
          !self.respond_to?(method_restrictor, true) || !self.send(method_restrictor)
        }.to_set
      end
    end
  end
end