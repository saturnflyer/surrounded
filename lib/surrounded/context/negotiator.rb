module Surrounded
  module Context
    class Negotiator
      behavior = "method_missing|respond_to?"
      identity = "__send__|object_id"

      instance_methods.each do |meth|
        unless meth.to_s =~ /initialize|#{behavior}|#{identity}/
          undef_method meth
        end
      end

      def initialize(object, behavior)
        @object, @behavior = object, behavior
      end

      def method_missing(meth, *args, &block)
        if @behavior.instance_methods.include?(meth)
          the_method = @behavior.instance_method(meth)
          the_method.bind(@object).call(*args, &block)
        else
          @object.send(meth, *args, &block)
        end
      end
    end
  end
end