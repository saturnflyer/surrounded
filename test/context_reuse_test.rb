require "test_helper"

describe Surrounded::Context, "reusing context object" do
  let(:user) { User.new("Jim") }
  let(:other_user) { User.new("Guille") }
  let(:context) { TestContext.new(user: user, other_user: other_user) }

  it "allows rebinding new players" do
    expect(context.access_other_object).must_equal "Guille"
    context.rebind(user: User.new("Amy"), other_user: User.new("Elizabeth"))
    expect(context.access_other_object).must_equal "Elizabeth"
  end

  it "clears internal storage when rebinding" do
    originals = context.instance_variables.map { |var| context.instance_variable_get(var) }
    context.rebind(user: User.new("Amy"), other_user: User.new("Elizabeth"))
    new_ivars = context.instance_variables.map { |var| context.instance_variable_get(var) }
    originals.zip(new_ivars).each do |original_ivar, new_ivar|
      expect(original_ivar).wont_equal new_ivar
    end
  end
end
