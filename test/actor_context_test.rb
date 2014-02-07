require 'test_helper'
require 'celluloid'
require 'celluloid/autostart'

class MultithreadUser
  include Surrounded
  include Celluloid
  
  def initialize(name)
    @name = name
  end
  attr_reader :name
end

class ActorContext
  extend Surrounded::Context

  def initialize(leader, members)
    role_names = [:leader, :members]
    role_players = [leader, members]

    role_names.concat(members.map{|member| :"member_#{member.object_id}" })
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

describe ActorContext do
  before do
    Celluloid.shutdown.
    Celluloid.boot
  end
  
  after do
    Celluloid.shutdown
  end
  
  let(:jim){ MultithreadUser.new('Jim') }
  let(:amy){ MultithreadUser.new('Amy') }
  let(:guille){ MultithreadUser.new('Guille') }
  let(:jason){ MultithreadUser.new('Jason') }
  let(:dave){ MultithreadUser.new('Dave') }

  let(:greeter){ jim }
  let(:members){ [amy, guille, jason, dave] }

  it 'works in multi-threaded environments' do
    meeting = ActorContext.new(jim, members)

    result = meeting.meet

    assert_includes result, 'Hello everyone. I am Jim'
    assert_includes result, 'Hello Jim, I am Amy'
  end
end