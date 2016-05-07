require 'triad'
module Surrounded
  module Context
    class InvalidRole < ::Triad::ItemNotPresent; end
    class InvalidRoleType < ::StandardError
      unless method_defined?(:cause)
        def initialize(msg=nil)
          super
          @cause = $!
        end
        attr_reader :cause
      end
    end
    class AccessError < ::StandardError; end
    class NameCollisionError <::StandardError; end
  end
end
