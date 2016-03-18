module Surrounded
  module Context
    module TriggerControls

      # Provides a Set of all available trigger methods where
      # behaviors will be applied to the roles before execution
      # and removed afterward.
      def triggers
        @triggers.dup
      end

      def store_trigger(*names)
        @triggers.merge(names)
      end

      # Creates a context instance method which will apply behaviors to role players
      # before execution and remove the behaviors after execution.
      #
      # Alternatively you may define your own methods then declare them as triggers
      # afterward.
      #
      # Example:
      #   trigger :some_event do
      #     # code here
      #   end
      #
      #   def some_event
      #     # code here
      #   end
      #   trigger :some_event
      #
      def trigger(*names, &block)
        if block.nil?
          names.each do |name|
            convert_method_to_trigger(name)
          end
        else
          name = names.first
          define_trigger_action(*names, &block)
          define_trigger(name)
          store_trigger(name)
        end
      end

      def convert_method_to_trigger(name)
        unless triggers.include?(name) || name.nil?
          alias_method :"__trigger_#{name}", :"#{name}"
          private :"__trigger_#{name}"
          remove_method :"#{name}"
          define_trigger(name)
          store_trigger(name)
        end
      end

      def define_trigger(name)
        line = __LINE__; self.class_eval %{
          def #{name}(*args, &block)
            begin
              apply_behaviors

              #{trigger_return_content(name)}

            ensure
              remove_behaviors
            end
          end
        }, __FILE__, line
      end

      def trigger_return_content(name)
        if method_defined?(name)
          %{super}
        else
          %{self.send("__trigger_#{name}", *args, &block)}
        end
      end


      def define_trigger_action(*name_and_args, &block)
        trigger_action_module.send(:define_method, *name_and_args, &block)
      end

      def trigger_action_module
        self.const_get('TriggerMethods', false)
      end
    end
  end
end
