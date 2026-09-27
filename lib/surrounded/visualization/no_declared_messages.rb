module Surrounded
  module Visualization
    # Stands in for DeclaredMessages when the source of the role methods
    # cannot be read. It listens to the roles and tells a template nothing.
    class NoDeclaredMessages
      # @return [self]
      def role(**)
        self
      end

      # @return [self]
      def tell(template)
        self
      end
    end
  end
end
