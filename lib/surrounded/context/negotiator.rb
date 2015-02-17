module Surrounded
  module Context
    class Negotiator
      identity = "__send__|object_id"

      instance_methods.each do |meth|
        unless meth.to_s =~ /#{identity}/
          undef_method meth
        end
      end

      private

      def initialize(object, behaviors)
        @object, @behaviors = object, behaviors
      end

      def method_missing(meth, *args, &block)
        if @behaviors.instance_methods.include?(meth)
          the_method = @behaviors.instance_method(meth)
          the_method.bind(@object).call(*args, &block)
        else
          @object.send(meth, *args, &block)
        end
      end
    end

    Negotiator.send(:prepend, Surrounded)
  end
end