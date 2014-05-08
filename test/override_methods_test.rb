require 'test_helper'

describe Surrounded::Context, 'custom role application' do
  it 'allows you to override existing methods on a role player' do
    class PrependedRoles
      extend Surrounded::Context
      
      initialize :user
      
      trigger :get_name do
        user.name
      end
      
      role :user do
        def name
          "Not what you thought, #{super}"
        end
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
    
    user = User.new('Jim')
    
    assert_equal "Not what you thought, Jim", PrependedRoles.new(user).get_name
    assert_equal "Jim", user.name
  end
end