module Surrounded
  module Visualization
    # Reads the roles of a context class and tells a listener about each one.
    #
    # The roles are the names given to the initializer of the context.
    class Roles
      NAMED = %i[req opt keyreq key].freeze

      # @param context_class [Class] a class extended with Surrounded::Context
      def initialize(context_class)
        @context_class = context_class
      end

      # @param listener [#role]
      # @return [self]
      def tell(listener)
        names.each { |name| Behavior.new(@context_class, name).tell(listener) }
        self
      end

      private

      def names
        @context_class.instance_method(:initialize).parameters.filter_map { |kind, name|
          name if NAMED.include?(kind)
        }
      end
    end
  end
end
