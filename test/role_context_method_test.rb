require "test_helper"

class RoleContextTester
  extend Surrounded::Context

  role_methods :admin do
  end
end

describe Surrounded::Context, ".role" do
  describe "modules" do
    it "creates a module" do
      role = RoleContextTester.const_get(:Admin)
      refute_instance_of Class, role
      assert_kind_of Module, role
    end

    it "marks the constant private" do
      error = assert_raises(NameError) {
        RoleContextTester::Admin
      }
      assert_match(/private constant/i, error.message)
    end
  end
end

class WrapperRoleContext
  extend Surrounded::Context

  role :admin, :wrap do
  end
end

describe Surrounded::Context, ".role" do
  describe "wrappers" do
    it "creates a wrapper" do
      role = WrapperRoleContext.const_get(:Admin)
      assert_includes(role.ancestors, SimpleDelegator)
    end

    it "marks the constant private" do
      error = assert_raises(NameError) {
        WrapperRoleContext::Admin
      }
      assert_match(/private constant/i, error.message)
    end
  end
end

class InterfaceContext
  extend Surrounded::Context

  initialize(:admin, :other)

  role :admin, :interface do
    def hello
      "hello from admin"
    end

    def splat_args(*args)
      args
    end

    def keyword_args(**kwargs)
      kwargs
    end

    def mixed_args(*args, **kwargs)
      [args, kwargs]
    end
  end

  trigger :admin_hello do
    admin.hello
  end

  trigger :splat_args do |*args|
    admin.splat_args(*args)
  end

  trigger :keyword_args do |**kwargs|
    admin.keyword_args(**kwargs)
  end

  trigger :mixed_args do |*args, **kwargs|
    admin.mixed_args(*args, **kwargs)
  end
end

class Hello
  include Surrounded

  def hello
    "hello"
  end
end

describe Surrounded::Context, ".role" do
  describe "interfaces" do
    let(:context) {
      InterfaceContext.new(admin: Hello.new, other: Hello.new)
    }
    it "sets interface objects to use interface methods before singleton methods" do
      assert_equal "hello from admin", context.admin_hello
    end

    it "marks the inteface constant private" do
      error = assert_raises(NameError) {
        InterfaceContext::AdminInterface
      }
      assert_match(/private constant/i, error.message)
    end

    it "creates a private accessor method" do
      assert context.respond_to?(:admin, true)
    end

    it "works with multiple args" do
      assert_equal context.splat_args("one", "two"), %w[one two]
    end

    it "works with multiple keyword args" do
      assert_equal context.keyword_args(one: "one", two: "two"), {one: "one", two: "two"}
    end

    it "works with multiple mixed args" do
      assert_equal context.mixed_args("one", :two, three: "three", four: "four"), [["one", :two], {three: "three", four: "four"}]
    end
  end
end

class UnknownRole
  extend Surrounded::Context
end

describe Surrounded::Context, ".role" do
  describe "unknown" do
    it "raises an error" do
      err = _ {
        UnknownRole.instance_eval do
          role :admin, :unknown do
          end
        end
      }.must_raise UnknownRole::InvalidRoleType
      _(err.cause).must_be_kind_of NameError
    end
  end
end

class CustomDefaultWrap
  extend Surrounded::Context

  self.default_role_type = :wrap

  initialize(:admin, :the_test)

  role :admin do
  end

  trigger :check_admin_type do
    the_test.assert_kind_of SimpleDelegator, admin
  end
end

describe Surrounded::Context, ".role" do
  describe "custom default" do
    include Surrounded # the test is a role player here

    it "allows the use of custom default role types" do
      context = CustomDefaultWrap.new(admin: Object.new, the_test: self)
      context.check_admin_type
    end

    it "allows the setting of custom default role type for all Surrounded::Contexts" do
      old_default = Surrounded::Context.default_role_type
      Surrounded::Context.default_role_type = :wrap

      # Define the class after setting the global default so it picks up the new default
      custom_global_default_class = Class.new do
        extend Surrounded::Context

        initialize(:admin, :the_test)

        role :admin do
        end

        trigger :check_admin_type do
          the_test.assert_kind_of SimpleDelegator, admin
        end
      end

      context = custom_global_default_class.new(admin: Object.new, the_test: self)
      context.check_admin_type
    ensure
      Surrounded::Context.default_role_type = old_default
    end
  end
end
