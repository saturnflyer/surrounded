require 'test_helper'

require 'casting'
class CastingUser < User
  include Casting::Client
  delegate_missing_methods
end