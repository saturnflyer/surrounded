require "triad"
require "forwardable"
module Surrounded
  module Context
    class RoleMap
      extend Forwardable

      class << self
        # Get the role map container and provide an alternative if desired
        # Ex: RoleMap.from_base(SomeCustomContainer)
        def from_base(klass = ::Triad)
          unless const_defined?(:Container)
            role_mapper = Class.new(self)
            role_mapper.container_class = (klass)
            Surrounded::Exceptions.define(role_mapper, exceptions: :ItemNotPresent, namespace: klass)
            const_set(:Container, role_mapper)
          end
          const_get(:Container)
        end

        attr_writer :container_class
      end

      def_delegators :container, :update, :each, :values, :keys

      def container
        @container ||= self.class.instance_variable_get(:@container_class).new
      end

      # Check if a role exists in the map
      def role?(role)
        keys.include?(role)
      end

      # Record the behaviored player applied to a role for the duration of a
      # trigger. The assigned domain object stays in the container; the player
      # (a wrapper, or the same object for cast roles) is tracked here.
      def apply(role, player)
        applied[role] = player
      end

      # The player a role currently presents: the applied player while a trigger
      # is running, otherwise the assigned domain object.
      def current_player(role)
        applied.fetch(role) { assigned_player(role) }
      end

      # Forget all applied players, e.g. after a trigger removes behaviors.
      def reset_applied
        applied.clear
      end

      # Check if an object is playing a role in this map, by identity — whether
      # it is the assigned domain object or the applied player wrapping it.
      def role_player?(object)
        values.any? { |player| player.equal?(object) } ||
          applied.values.any? { |player| player.equal?(object) }
      end

      # Get the domain object assigned to the given role
      def assigned_player(role)
        values(role).first
      end

      private

      def applied
        @applied ||= {}
      end
    end
  end
end
