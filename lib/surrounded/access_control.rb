module Surrounded
  module AccessControl
    def self.extended(base)
      base.send(:include, AccessMethods)
    end
    
    private
    
    def disallow(*names, &block)
      names.map do |name|
        define_method("disallow_#{name}?", &block)
      end
    end
    
    def redo_method(name)
      class_eval %{
        def #{name}
          begin
            apply_roles if __apply_role_policy == :trigger
            
            method_restrictor = "disallow_#{name}?"
            if self.respond_to?(method_restrictor, true) && self.send(method_restrictor)
              raise ::Surrounded::Context::AccessError.new("access to `#{name}' is not allowed")
            end
            
            self.send("__trigger_#{name}")

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