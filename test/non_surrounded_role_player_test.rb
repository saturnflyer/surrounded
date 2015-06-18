require 'test_helper'

class BareObjectContext
  extend Surrounded::Context

  def initialize(number, string, user)
    map_roles(:number => number, :string => string, :user => user)
  end
  private_attr_reader :number, :string, :user

  role :user do
    def output
      [number.to_s, string, name].join(' - ')
    end
  end

  trigger :output do
    user.output
  end
end

describe Surrounded::Context, 'skips affecting non-surrounded objects' do
  it 'works with non-surrounded objects' do
    context = BareObjectContext.new(123,'hello', User.new('Jim'))
    assert_equal '123 - hello - Jim', context.output
  end
end