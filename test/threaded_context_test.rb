require "test_helper"
require "async"

class ThreadedContext
  extend Surrounded::Context

  def initialize(leader:, members:)
    role_names = [:leader, :members]
    role_players = [leader, members]

    role_names.concat(members.map { |member| :"member_#{member.object_id}" })
    role_players.concat(members)

    map_roles(role_names.zip(role_players))
  end
  private_attr_reader :leader, :members

  trigger :meet do
    result = []
    result << leader.greet
    result << members.concurrent_map do |member|
      result << member.greet
    end
    result.flatten.join(" ")
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
    include Surrounded

    def concurrent_map
      Async do
        map do |member|
          yield member
        end
      end
    end
  end
end

describe ThreadedContext do
  let(:jim) { User.new("Jim") }
  let(:amy) { User.new("Amy") }
  let(:guille) { User.new("Guille") }
  let(:jason) { User.new("Jason") }
  let(:dave) { User.new("Dave") }

  let(:greeter) { jim }
  let(:members) { [amy, guille, jason, dave] }

  it "works in multi-threaded environments" do
    meeting = ThreadedContext.new(leader: jim, members: members)

    result = meeting.meet

    assert_includes result, "Hello everyone. I am Jim"
    assert_includes result, "Hello Jim, I am Amy"
  end
end
