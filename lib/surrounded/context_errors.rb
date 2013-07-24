require 'triad'
module Surrounded
  module Context
    class InvalidRole < ::Triad::KeyNotPresent; end
    class InvalidRoleType < StandardError; end
  end
end