require "test_helper"

class Sending
  extend Surrounded::Context

  initialize :one, :two

  forwarding [:hello, :goodbye] => :one
  forward_trigger :two, :ping
  forward_trigger :two, :argumentative
  forwards :two, :blockhead

  role :one do
    def hello
      "hello"
    end

    def goodbye
      "goodbye"
    end
  end

  role :two do
    def ping
      one.hello
    end

    def argumentative(yes, no)
      [yes, no].join(" and ")
    end

    def blockhead
      yield
    end
  end
end

describe Surrounded::Context, "forwarding triggers" do
  let(:user) { User.new("Jim") }
  let(:other_user) { User.new("Guille") }
  let(:context) { Sending.new(one: user, two: other_user) }

  it "forwards multiple configured instance methods as triggers" do
    assert_equal "hello", context.hello
    assert_equal "goodbye", context.goodbye
  end

  it "forwards individual configured instance methods as triggers" do
    assert_equal "hello", context.ping
  end

  it "does not forward __id__" do
    error = assert_raises(ArgumentError) {
      Sending.class_eval do
        forward_trigger :one, :__id__
      end
    }
    assert_match(/you may not forward '__id__`/i, error.message)
  end

  it "does not forward __send__" do
    error = assert_raises(ArgumentError) {
      Sending.class_eval do
        forward_trigger :one, :__send__
      end
    }
    assert_match(/you may not forward '__send__/i, error.message)
  end

  it "passes arguments" do
    assert_equal "YES and NO", context.argumentative("YES", "NO")
  end

  it "passes blocks" do
    result = context.blockhead do
      "Put them in the iron maiden. Excellent!"
    end
    assert_equal "Put them in the iron maiden. Excellent!", result
  end
end
