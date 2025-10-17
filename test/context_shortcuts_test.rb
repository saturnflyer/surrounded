require "test_helper"

class ShortcutContext
  extend Surrounded::Context

  shortcut_triggers

  initialize :user, :other

  trigger :shorty do
    user.speak
  end

  role :user do
    def speak
      "it works, shorty!"
    end
  end
end

class ShortcutContextNoKeywords
  extend Surrounded::Context

  shortcut_triggers

  initialize_without_keywords :user, :other

  trigger :shorty do
    user.speak
  end

  role :user do
    def speak
      "it works, shorty!"
    end
  end
end

describe Surrounded::Context, "shortcuts" do
  let(:user) { User.new("Jim") }
  let(:other) { User.new("Guille") }
  it "creates shortcut class methods for triggers" do
    assert_equal "it works, shorty!", ShortcutContext.shorty(user: user, other: other)
  end
end

describe Surrounded::Context, "shortcuts with initialize_without_keywords" do
  let(:user) { User.new("Jim") }
  let(:other) { User.new("Guille") }
  it "creates shortcut class methods for triggers" do
    assert_equal "it works, shorty!", ShortcutContextNoKeywords.shorty(user, other)
  end
end
