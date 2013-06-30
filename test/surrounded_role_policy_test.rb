require 'test_helper'

class RolesOnInitialize
  extend Surrounded::Context

  apply_roles_on(:initialize)
  initialize(:admin, :user)

  trigger :check_roles_already_applied_during_trigger do
    admin.respond_to?(:admin_method)
  end

  def check_roles_applied_on_initialize
    admin.respond_to?(:admin_method)
  end

  module Admin
    def admin_method; end
  end
end

describe Surrounded::Context, 'applying roles on initialize' do
  let(:context){ RolesOnInitialize.new(Object.new, Object.new) }
  it 'has role methods available when initialized' do
    assert context.check_roles_applied_on_initialize
  end

  it 'has role methods available during triggers' do
    assert context.check_roles_already_applied_during_trigger
  end
end

class RolesOnTrigger
  extend Surrounded::Context

  apply_roles_on(:trigger)
  initialize(:admin, :user)

  trigger :check_roles_already_applied_during_trigger do
    admin.respond_to?(:admin_method)
  end

  def check_roles_applied_on_initialize
    admin.respond_to?(:admin_method)
  end

  module Admin
    def admin_method; end
  end
end

describe Surrounded::Context, 'applying roles on initialize' do
  let(:context){ RolesOnTrigger.new(Object.new, Object.new) }
  it 'has NO role methods available when initialized' do
    refute context.check_roles_applied_on_initialize
  end

  it 'has role methods available during triggers' do
    assert context.check_roles_already_applied_during_trigger
  end
end