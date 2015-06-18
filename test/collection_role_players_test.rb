require 'test_helper'

class CollectionContext
  extend Surrounded::Context

  initialize :members, :others

  trigger :get_members_count do
    members.member_count
  end

  trigger :get_member_show do
    members.map(&:show).join(', ')
  end

  role :members do
    def member_count
      size
    end
  end

  role :member do
    def show
      "member show"
    end
  end

  role :others do; end
  role :other do; end

end

describe Surrounded::Context, 'auto-assigning roles for collections' do
  let(:member_one){ User.new('Jim') }
  let(:member_two){ User.new('Amy') }
  let(:members){ [member_one, member_two] }

  let(:other_one){ User.new('Guille') }
  let(:other_two){ User.new('Jason') }
  let(:others){ [other_one, other_two] }

  let(:context){ CollectionContext.new(members, others) }

  it 'assigns the collection role to collections' do
    assert_equal members.size, context.get_members_count
  end

  it 'assigns a defined role to each item in a role player collection' do
    assert_equal "member show, member show", context.get_member_show
  end
end