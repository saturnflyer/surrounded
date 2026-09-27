require "visualization_test_helper"

describe Surrounded::Visualization::Markdown do
  let(:page) { Surrounded::Visualization::Markdown.new }

  it "writes the context, roles, triggers, and messages between roles" do
    Surrounded::Visualization.describe(Visualized::MoneyTransfer, to: page)

    expect(page.to_s).must_equal <<~MARKDOWN
      # Visualized::MoneyTransfer

      Defined in `test/visualization_test_helper.rb`.

      ## Roles

      | Role | Type | Methods |
      |---|---|---|
      | depositor | module | `withdraw_and_send` |
      | recipient | wrap | `receive` |
      | ledger | interface | `record` |
      | auditor | delegate class | `review` |

      ## Triggers

      - `transfer`
      - `audit`
      - `send_amount`

      ## Messages between roles

      | From | In | To | Message |
      |---|---|---|---|
      | depositor | `withdraw_and_send` | recipient | `receive` |
      | depositor | `withdraw_and_send` | ledger | `record` |
      | auditor | `review` | ledger | `entries` |
    MARKDOWN
  end

  it "writes the players" do
    Surrounded::Visualization.cast(Visualized::Players.transfer, to: page, names: {ledger: "Book"})

    expect(page.to_s).must_equal <<~MARKDOWN
      # Context

      ## Players

      | Role | Player | Class |
      |---|---|---|
      | depositor | Alice | `Visualized::Account` |
      | recipient | Bob | `Visualized::Account` |
      | ledger | Book | `Visualized::Ledger` |
      | auditor | Casey | `Visualized::Clerk` |
    MARKDOWN
  end

  it "writes a run" do
    page.context(name: "MoneyTransfer")
    Surrounded::Visualization.record(Visualized::Players.transfer, :transfer, to: page, names: {ledger: "Book"})

    expect(page.to_s).must_equal <<~MARKDOWN
      # MoneyTransfer

      ## Run of `transfer`

      | Role | Player | Class |
      |---|---|---|
      | depositor | Alice | `Visualized::Account` |
      | recipient | Bob | `Visualized::Account` |
      | ledger | Book | `Visualized::Ledger` |
      | auditor | Casey | `Visualized::Clerk` |

      1. MoneyTransfer tells depositor `withdraw_and_send(100)`
      2. depositor tells recipient `receive(100)`
      3. depositor tells ledger `record("Alice", 100)`

      Returned `1`.

      `withdraw_and_send` is still on the depositor player.
    MARKDOWN
  end

  it "writes a run which was disallowed" do
    context = Visualized::Players.transfer(depositor: Visualized::Account.new("Dana", 20))
    Surrounded::Visualization.record(context, :transfer, to: page)

    expect(page.to_s).must_include "Disallowed: access to Visualized::MoneyTransfer#transfer is not allowed"
  end

  it "writes a run which failed" do
    context = Visualized::Players.transfer(ledger: Visualized::Clerk.new("Casey"))
    Surrounded::Visualization.record(context, :transfer, to: page)

    expect(page.to_s).must_match(/^Failed in ledger with `NameError`: .*entries/)
  end

  # What is expected here was shown to be right by the way GitHub draws it.
  describe "values with a bar or a backslash in them" do
    def player(label:, class_name: "Court")
      page.player(role: :judge, label: label, class_name: class_name, methods: [], state: {})
    end

    it "keeps the columns of a table when code has a bar in it" do
      page.role(name: :judge, type: :module, methods: [:|])

      expect(page.to_s).must_include '| judge | module | `\|` |'
    end

    it "keeps the columns of a table when text has a bar in it" do
      player(label: "left|right")

      expect(page.to_s).must_include '| judge | left\|right | `Court` |'
    end

    it "keeps a backslash in the text of a table" do
      player(label: 'C:\temp')

      expect(page.to_s).must_include '| judge | C:\\\\temp | `Court` |'
    end

    it "keeps a backslash which comes before a bar in the text of a table" do
      player(label: 'left\|right')

      expect(page.to_s).must_include '| judge | left\\\\\|right | `Court` |'
    end

    it "keeps a backslash at the end of the text of a table" do
      player(label: "left\\")

      expect(page.to_s).must_include '| judge | left\\\\ | `Court` |'
    end

    it "leaves a backslash alone in the code of a table" do
      player(label: "Judge", class_name: 'Left\|Right')

      expect(page.to_s).must_include '| judge | Judge | `Left\\\|Right` |'
    end

    it "leaves a bar and a backslash alone in code outside of a table" do
      page.run(trigger: :decide)
      page.returned(value: '"left|right\\\\n"')

      expect(page.to_s).must_include 'Returned `"left|right\\\\n"`.'
    end

    it "keeps a bar and a backslash in text outside of a table" do
      page.run(trigger: :decide)
      page.failed(error: "Errno::ENOENT", message: 'C:\temp | missing', role: :judge)

      expect(page.to_s).must_include 'Failed in judge with `Errno::ENOENT`: C:\\\\temp \| missing'
    end
  end

  it "writes to what it is given" do
    output = StringIO.new
    page.context(name: "MoneyTransfer")

    expect(page.write_to(output)).must_be_same_as page
    expect(output.string).must_equal "# MoneyTransfer\n"
  end
end
