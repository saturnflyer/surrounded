require 'test_helper'

describe Surrounded::Context, '.role' do
  class RoleContextTester
    extend Surrounded::Context

    role_methods :admin do
    end
  end

  describe 'modules' do
    it 'creates a module' do
      role = RoleContextTester.const_get(:Admin)
      refute_instance_of Class, role
      assert_kind_of Module, role
    end

    it 'marks the constant private' do
      error = assert_raises(NameError){
        RoleContextTester::Admin
      }
      assert_match(/private constant/i, error.message)
    end
  end

  class WrapperRoleContext
    extend Surrounded::Context

    role :admin, :wrap do

    end
  end

  describe 'wrappers' do
    it 'creates a wrapper' do
      role = WrapperRoleContext.const_get('Admin')
      assert_includes(role.ancestors, SimpleDelegator)
    end

    it 'marks the constant private' do
      error = assert_raises(NameError){
        WrapperRoleContext::Admin
      }
      assert_match(/private constant/i, error.message)
    end
  end
  if test_rebinding_methods?
    class InterfaceContext
      extend Surrounded::Context

      initialize(:admin, :other)

      role :admin, :interface do
        def hello
          'hello from admin'
        end
      end

      trigger :admin_hello do
        admin.hello
      end
    end

    class Hello
      def hello
        'hello'
      end
    end

    describe 'interfaces' do
      let(:context){
        InterfaceContext.new(Hello.new, Hello.new)
      }
      it 'sets interface objects to use interface methods before singleton methods' do
        assert_equal 'hello from admin', context.admin_hello
      end

      it 'marks the inteface constant private' do
        error = assert_raises(NameError){
          InterfaceContext::AdminInterface
        }
        assert_match(/private constant/i, error.message)
      end

      it 'creates a private accessor method' do
        assert_respond_to(context, :admin)
      end
    end
  end

  describe 'unknown' do
    it 'raises an error' do
      assert_raises(Surrounded::Context::InvalidRoleType){
        class UnknownRole
          extend Surrounded::Context

          role :admin, :unknown do
          end
        end
      }
    end
  end

  describe 'custom default' do
    it 'allows the use of custom default role types' do
      class CustomDefaultWrap
        extend Surrounded::Context

        self.default_role_type = :wrap
        apply_roles_on(:initialize)

        initialize(:admin)

        role :admin do
        end
      end
      context = CustomDefaultWrap.new(Object.new)
      assert_kind_of(SimpleDelegator, context.send(:admin))
    end

    it 'allows the setting of custom default role time for all Surrounded::Contexts' do
      begin
        old_default = Surrounded::Context.default_role_type
        Surrounded::Context.default_role_type = :wrap
        class CustomGlobalDefault
          extend Surrounded::Context
          apply_roles_on(:initialize)

          initialize(:admin)

          role :admin do
          end
        end

        context = CustomGlobalDefault.new(Object.new)
        assert_kind_of(SimpleDelegator, context.send(:admin))
      ensure
        Surrounded::Context.default_role_type = old_default
      end
    end
  end
end