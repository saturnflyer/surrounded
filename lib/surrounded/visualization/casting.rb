module Surrounded
  module Visualization
    # Reads which object plays each role in a context and tells a listener.
    class Casting
      # @param context [Object] an instance of a context class
      # @param names [Hash] labels for players, keyed by role
      def initialize(context, names: {})
        @context = context
        @names = names
      end

      # @param listener [#player]
      # @return [self]
      def tell(listener)
        @context.send(:role_map).each do |role, _behavior, object|
          listener.player(
            role: role,
            label: label(role, object),
            class_name: object.class.name.to_s,
            methods: object.class.public_instance_methods(false).sort,
            state: state(object)
          )
        end
        self
      end

      private

      def label(role, object)
        return @names[role].to_s if @names.key?(role)

        name = object.name if object.respond_to?(:name)
        case name
        when String, Symbol then name.to_s
        else object.class.name.to_s
        end
      end

      def state(object)
        object.instance_variables
          .reject { |name| name.start_with?("@__") }
          .to_h { |name| [name.to_s.delete_prefix("@"), Inspection.of(object.instance_variable_get(name))] }
      end
    end

    # A short description of a value, without the address of the object.
    module Inspection
      LIMIT = 80

      def self.of(value)
        tidy(value.inspect)
      rescue
        value.class.name.to_s
      end

      def self.tidy(text)
        text = text.to_s.lines.first.to_s.strip.gsub(/#<([\w:]+):0x\h+[^>]*>/, 'an instance of \1')
        (text.length > LIMIT) ? "#{text[0, LIMIT - 1]}…" : text
      end
    end
  end
end
