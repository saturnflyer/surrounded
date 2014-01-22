require 'triad'
module Surrounded
  module Context
    class InvalidRole < ::Triad::KeyNotPresent; end
    module InvalidRoleType; end
    class AccessError < ::StandardError; end
  end
end