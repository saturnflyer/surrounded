require 'triad'
require 'surrounded/context_errors'
module Surrounded
  module Context
    class RoleMap < Triad
      def role?(role)
        keys.include?(role)
      end

      def role_player?(object)
        !values(object).empty?
      rescue ::Triad::ValueNotPresent
        false
      end

      def assigned_player(role)
        values(role).first
      rescue ::Triad::KeyNotPresent
        raise Surrounded::Context::InvalidRole.new
      end
    end
  end
end