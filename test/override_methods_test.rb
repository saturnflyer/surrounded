require "test_helper"

class PrependedRoles
  extend Surrounded::Context

  initialize :user, :other

  trigger :get_name do
    user.name
  end

  trigger :other_title do
    other.title
  end

  role :user do
    def name
      "Not what you thought, #{super}"
    end
  end

  module OtherStuff
    def title
      "OtherStuff #{name}"
    end
  end

  def map_role_other(role_player)
    @other = role_player
    map_role(:other, OtherStuff, role_player)
  end

  def apply_behavior_user(mod, object)
    mod.instance_methods.each do |meth|
      object.singleton_class.send(:define_method, meth, mod.instance_method(meth))
    end
    object
  end

  def remove_behavior_user(mod, object)
    mod.instance_methods.each do |meth|
      object.singleton_class.send(:remove_method, meth)
    end
    object
  end
end

describe Surrounded::Context, "custom role application" do
  let(:user) { User.new("Jim") }
  let(:other) { User.new("Amy") }

  let(:context) { PrependedRoles.new(user: user, other: other) }

  it "allows you to override existing methods on a role player" do
    assert_equal "Not what you thought, Jim", context.get_name
    assert_equal "Jim", user.name
  end

  it "allows you to override the way a role is mapped" do
    assert_equal "OtherStuff Amy", context.other_title
  end
end
