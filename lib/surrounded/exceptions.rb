module Surrounded
  module Exceptions
    def self.define(klass, exceptions:, namespace: Surrounded::Context)
      Array(exceptions).each { |exception|
        unless klass.const_defined?(exception)
          klass.const_set(exception, Class.new(namespace.const_get(exception)))
        end
      }
    end
  end
end
