require 'test_helper'
require 'debugger'

class Person
  include Surrounded
  attr_reader :name
  def initialize(name)
    @name = name
  end
end

class ThreadedContext
  extend Surrounded::Context

  def initialize(leader, members)
    map_roles([[:leader, leader], [:members, members]])
    @leader, @members = leader, members
    members.each do |member|
      role = :"member_#{member.object_id}"
      role_map << [role, 'Member', member]
    end
  end
  private_attr_reader :leader, :members

  trigger :meet do
    result = []
    result << leader.greet
    result << members.threaded_map do |member|
      result << member.greet
    end.each(&:join)
    result.flatten.join(' ')
  end

  module Leader
    def greet
      "Hello everyone. I am #{name}"
    end
  end

  module Member
    def greet
      "Hello #{leader.name}, I am #{name}"
    end
  end

  module Members
    def threaded_map
      map do |member|
        Thread.new do
          yield member
        end
      end
    end
  end
end

describe ThreadedContext do
  let(:jim){ Person.new('Jim') }
  let(:amy){ Person.new('Amy') }
  let(:guille){ Person.new('Guille') }
  let(:jason){ Person.new('Jason') }
  let(:dave){ Person.new('Dave') }

  let(:greeter){ jim }
  let(:members){ [amy, guille, jason, dave] }

  it 'works in multi-threaded environments' do
    meeting = ThreadedContext.new(jim, members)
    result = meeting.meet

    assert_includes result, 'Hello everyone. I am Jim'
    assert_includes result, 'Hello Jim, I am Amy'
  end
end