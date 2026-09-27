require "test_helper"

class NestedTriggerContext
  extend Surrounded::Context

  initialize :sender, :wrapped, :negotiated

  trigger :inner do
    sender.ask_wrapped
  end

  trigger :outer do
    [inner, sender.ask_wrapped, sender.ask_negotiated]
  end

  trigger :failing_inner do
    raise ArgumentError, "inner trigger failed"
  end

  trigger :recovering do
    begin
      failing_inner
    rescue ArgumentError
      # continue with the outer trigger
    end
    sender.ask_negotiated
  end

  role :sender do
    def ask_wrapped
      wrapped.wrapped_answer
    end

    def ask_negotiated
      negotiated.negotiated_answer
    end
  end

  role :wrapped, :wrap do
    def wrapped_answer
      "wrapped #{name}"
    end
  end

  role :negotiated, :interface do
    def negotiated_answer
      "negotiated #{name}"
    end
  end
end

describe Surrounded::Context, "triggers which run other triggers" do
  let(:sender) { User.new("Jim") }
  let(:wrapped) { User.new("Guille") }
  let(:negotiated) { User.new("Jason") }
  let(:context) {
    NestedTriggerContext.new(sender: sender, wrapped: wrapped, negotiated: negotiated)
  }

  it "keeps behavior applied until the outer trigger finishes" do
    expect(context.outer).must_equal ["wrapped Guille", "wrapped Guille", "negotiated Jason"]
  end

  it "keeps behavior applied when an inner trigger raises an error" do
    expect(context.recovering).must_equal "negotiated Jason"
  end

  it "removes behavior after the outer trigger finishes" do
    context.outer

    expect(wrapped).wont_respond_to :wrapped_answer
    expect { sender.ask_wrapped }.must_raise NameError
  end

  it "removes behavior when the outer trigger raises an error" do
    expect { context.failing_inner }.must_raise ArgumentError

    expect { sender.ask_wrapped }.must_raise NameError
    expect(context.inner).must_equal "wrapped Guille"
  end
end
