require "test_helper"

class ThreadedContext
  extend Surrounded::Context

  initialize :leader, :members

  trigger :meet do
    leader.welcome
  end

  module Leader
    def welcome
      result = []
      result << leader.greet
      result << members.concurrent_map do |member|
        result << member.greet
      end
      result.flatten.join(" ")
    end

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
      map do |member|
        Thread.new do
          yield member
        end
      end.each(&:join)
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
