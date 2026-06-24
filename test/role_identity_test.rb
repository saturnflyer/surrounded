require "test_helper"

# Refuses value-equality so resolution must use object identity.
class IdentityResistant
  include Surrounded

  def initialize(name)
    @name = name
  end
  attr_reader :name

  def ==(other) = false
  def eql?(other) = false
  def hash = object_id
end

class SpeakerContext
  extend Surrounded::Context

  initialize :speaker, :listener

  interface :speaker do
    def greet
      listener.name
    end
  end

  trigger :speak do
    speaker.greet
  end
end

describe "role identity independent of equality" do
  it "resolves a sibling role by object identity, not ==" do
    a = IdentityResistant.new("A")
    b = IdentityResistant.new("B")
    expect(SpeakerContext.new(speaker: a, listener: b).speak).must_equal "B"
  end
end
