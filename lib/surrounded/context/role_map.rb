require 'triad'
module Surrounded
  module Context
    class InvalidRole < ::Triad::ItemNotPresent; end

    class RoleMap

      class << self
        def from_base(klass=::Triad)
          role_mapper = Class.new(::Surrounded::Context::RoleMap)
          num = __LINE__; role_mapper.class_eval %{
            def container
              @container ||= #{klass}.new
            end
          }, __FILE__, num
          %w{ update each values keys }.each do |meth|
            num = __LINE__; role_mapper.class_eval %{
              def #{meth}(*args, &block)
                container.send(:#{meth}, *args, &block)
              end
            }, __FILE__, num
          end
          role_mapper
        end
      end

      def role?(role)
        keys.include?(role)
      end

      def role_player?(object)
        !values(object).empty?
      rescue ::Triad::ItemNotPresent
        false
      end

      def assigned_player(role)
        values(role).first
      end
    end
  end
end