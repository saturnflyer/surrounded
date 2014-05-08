require 'triad'
module Surrounded
  module Context
    class InvalidRole < ::Triad::ItemNotPresent; end
    module InvalidRoleType; end
    class AccessError < ::StandardError; end
  end
end