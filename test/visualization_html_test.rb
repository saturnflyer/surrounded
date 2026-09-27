require "visualization_test_helper"
require "json"

describe Surrounded::Visualization::Html do
  let(:page) { Surrounded::Visualization::Html.new }
  let(:written) { page.to_s }
  let(:data) { JSON.parse(written[/const DATA = (.*?);<\/script>/m, 1].gsub("<\\/", "</")) }

  def record(trigger, names: {ledger: "Book"}, **players)
    Surrounded::Visualization.record(Visualized::Players.transfer(**players), trigger, to: page, names: names)
  end

  it "is a page" do
    expect(written).must_match(/\A<!doctype html>/)
    expect(written).wont_include Surrounded::Visualization::Html::DATA
  end

  it "needs nothing from the network" do
    addresses = written.scan(/https?:\/\/[^\s"')]+/).uniq

    expect(addresses).must_equal ["http://www.w3.org/2000/svg"]
  end

  it "holds the context which was described" do
    Surrounded::Visualization.describe(Visualized::MoneyTransfer, to: page)

    expect(data["context"]).must_equal "Visualized::MoneyTransfer"
    expect(data["source"]).must_equal "test/visualization_test_helper.rb"
    expect(data["surrounded"]).must_equal Surrounded.version
    expect(data["triggers"]).must_equal %w[transfer audit send_amount]
    expect(data["roles"].map { |role| role.values_at("name", "type", "methods") }).must_equal [
      ["depositor", "module", ["withdraw_and_send"]],
      ["recipient", "wrap", ["receive"]],
      ["ledger", "interface", ["record"]],
      ["auditor", "delegate_class", ["review"]]
    ]
    expect(data["static_messages"].first).must_equal(
      {"from" => "depositor", "to" => "recipient", "method" => "receive", "via" => "withdraw_and_send", "role_method" => true}
    )
  end

  it "holds each player once" do
    Surrounded::Visualization.describe(Visualized::MoneyTransfer, to: page)
    record(:transfer)
    record(:audit)

    expect(data["objects"].map { |object| object.values_at("key", "label", "class") }).must_equal [
      ["alice", "Alice", "Visualized::Account"],
      ["bob", "Bob", "Visualized::Account"],
      ["book", "Book", "Visualized::Ledger"],
      ["casey", "Casey", "Visualized::Clerk"]
    ]
    expect(data["objects"].first["state"]).must_equal({"name" => '"Alice"', "balance" => "500"})
  end

  it "holds the runs for each cast of players" do
    Surrounded::Visualization.describe(Visualized::MoneyTransfer, to: page)
    record(:transfer)
    record(:audit)
    record(:transfer, depositor: Visualized::Account.new("Dana", 20))

    expect(data["scenarios"].keys).must_equal ["alice,bob,book,casey", "dana,bob,book,casey"]
    expect(data["scenarios"]["alice,bob,book,casey"].keys).must_equal %w[transfer audit]

    transfer = data["scenarios"]["alice,bob,book,casey"]["transfer"]
    expect(transfer["allowed"]).must_equal true
    expect(transfer["result"]).must_equal "1"
    expect(transfer["error"]).must_be_nil
    expect(transfer["messages"].last).must_equal(
      {"from" => "depositor", "to" => "ledger", "method" => "record", "args" => ['"Alice"', "100"]}
    )

    expect(data["scenarios"]["dana,bob,book,casey"]["transfer"]["allowed"]).must_equal false
  end

  it "holds where a run failed" do
    Surrounded::Visualization.describe(Visualized::MoneyTransfer, to: page)
    record(:transfer, ledger: Visualized::Clerk.new("Casey"), auditor: Visualized::Clerk.new("Morgan"), names: {})
    error = data["scenarios"]["alice,bob,casey,morgan"]["transfer"]["error"]

    expect(error["class"]).must_equal "NameError"
    expect(error["in"]).must_equal "ledger"
  end

  it "holds what is left on the players" do
    Surrounded::Visualization.describe(Visualized::MoneyTransfer, to: page)
    record(:transfer)
    record(:transfer)

    expect(data["roles"].map { |role| role["left_behind"] }).must_equal [
      [{"method" => "withdraw_and_send"}], [], [], []
    ]
  end

  it "begins with the players from the first run" do
    Surrounded::Visualization.describe(Visualized::MoneyTransfer, to: page)
    record(:transfer, depositor: Visualized::Account.new("Dana", 20))
    record(:transfer)

    expect(data["default_cast"]).must_equal(
      {"depositor" => "dana", "recipient" => "bob", "ledger" => "book", "auditor" => "casey"}
    )
  end

  it "begins with the players which were cast" do
    Surrounded::Visualization.describe(Visualized::MoneyTransfer, to: page)
    record(:transfer, depositor: Visualized::Account.new("Dana", 20))
    Surrounded::Visualization.cast(Visualized::Players.transfer, to: page, names: {ledger: "Book"})

    expect(data["default_cast"]["depositor"]).must_equal "alice"
  end

  it "has no players to begin with when none were told" do
    Surrounded::Visualization.describe(Visualized::MoneyTransfer, to: page)

    expect(data["default_cast"]).must_be_nil
    expect(data["objects"]).must_equal []
  end

  it "tells apart players of different classes with the same name" do
    Surrounded::Visualization.describe(Visualized::MoneyTransfer, to: page)
    record(:audit, auditor: Visualized::Clerk.new("Alice"))

    expect(data["objects"].map { |object| object["key"] }).must_equal %w[alice bob book alice-visualized-clerk]
  end

  it "keeps the page whole when a name would end the script" do
    Surrounded::Visualization.describe(Visualized::MoneyTransfer, to: page)
    record(:audit, depositor: Visualized::Account.new("</script><p>Alice", 500))

    expect(written.scan("</script>").size).must_equal Surrounded::Visualization::Html.new.to_s.scan("</script>").size
    expect(data["objects"].first["label"]).must_equal "</script><p>Alice"
  end

  it "fills the page it is given" do
    page = Surrounded::Visualization::Html.new(page: "<pre>#{Surrounded::Visualization::Html::DATA}</pre>")
    page.context(name: "MoneyTransfer")

    expect(page.to_s).must_match(/\A<pre>\{"context":"MoneyTransfer",.*\}<\/pre>\z/)
  end

  it "writes to what it is given" do
    output = StringIO.new

    expect(page.write_to(output)).must_be_same_as page
    expect(output.string).must_equal written
  end
end
