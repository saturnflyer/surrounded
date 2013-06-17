# If you want to use wrappers, here's how you could

require 'surrounded/context'
require 'delegate'
class WrapperContext
  extend Surrounded::Context

  apply_roles_on(:trigger)
  setup(:admin, :task)

  class Admin < SimpleDelegator
    def some_admin_method
      puts 'hello from the admin wrapper!'
    end
  end

  trigger :do_something do
    admin.some_admin_method
  end

  private

  def add_role_methods(obj, wrapper)
    assign_role(role_name(wrapper), wrapper.new(obj))
  end

  def remove_role_methods(obj, wrapper)
    # in this case, the obj is already wrapped
    core_object = self.send(role_name(wrapper)).__getobj__
    assign_role(role_name(wrapper), core_object)
  end

  def role_name(klass)
    klass.name.split("::").last.gsub(/([A-Z])/){ "_#{$1.downcase}" }.sub(/^_/,'')
  end
end

context = WrapperContext.new(Object.new, Object.new)
context.do_something