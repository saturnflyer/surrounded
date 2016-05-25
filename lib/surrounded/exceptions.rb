module Surrounded
  module Exceptions
    def self.define(klass, exceptions:)
      Array(exceptions).each{ |exception|
        unless klass.const_defined?(exception)
          klass.const_set(exception, Class.new(Surrounded::Context.const_get(exception)))
        end
      }
    end
  end
end
