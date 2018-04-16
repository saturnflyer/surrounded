require 'triad'
require 'forwardable'
module Surrounded
  module Context
    class RoleMap
      extend Forwardable

      class << self
        def from_base(klass=::Triad)
          unless const_defined?(:Container)
            role_mapper = Class.new(self)
            role_mapper.container_class=(klass)
            Surrounded::Exceptions.define(role_mapper, exceptions: :ItemNotPresent, namespace: klass)
            const_set(:Container, role_mapper)
          end
          const_get(:Container)
        end

        def container_class=(klass)
          @container_class = klass
        end
      end

      def_delegators :container, :update, :each, :values, :keys

      def container
        @container ||= self.class.instance_variable_get(:@container_class).new
      end

      def role?(role)
        keys.include?(role)
      end

      def role_player?(object)
        !values(object).empty?
      rescue self.container.class::ItemNotPresent
        false
      end

      def assigned_player(role)
        values(role).first
      end
    end
  end
end
