require "visualization_test_helper"

describe Surrounded::Visualization::Svg do
  let(:image) { Surrounded::Visualization::Svg.new }
  let(:drawn) { image.to_s }

  describe "a context" do
    before do
      Surrounded::Visualization.describe(Visualized::MoneyTransfer, to: image)
    end

    it "is an image" do
      expect(drawn).must_match(/\A<svg xmlns="http:\/\/www.w3.org\/2000\/svg"/)
      expect(drawn).must_match(/<\/svg>\n\z/)
    end

    it "names the context and its triggers" do
      expect(drawn).must_include ">Visualized::MoneyTransfer</text>"
      expect(drawn).must_include ">triggers: transfer, audit, send_amount</text>"
    end

    it "draws the context and a circle for each role" do
      expect(drawn.scan("<circle").size).must_equal 5
    end

    it "names each role and its methods" do
      %w[depositor recipient ledger auditor withdraw_and_send receive record review].each do |name|
        expect(drawn).must_include ">#{name}</text>"
      end
    end

    it "draws the messages between roles" do
      expect(drawn.scan("<line").size).must_equal 3
      expect(drawn).must_include ">entries</text>"
    end

    it "shows the roles waiting for players" do
      expect(drawn.scan(">no player</text>").size).must_equal 4
      expect(drawn.scan("stroke-dasharray").size).must_equal 4
    end
  end

  it "draws the players in their roles" do
    Surrounded::Visualization
      .describe(Visualized::MoneyTransfer, to: image)
      .cast(Visualized::Players.transfer, to: image)

    expect(drawn).must_include ">Alice (Visualized::Account)</text>"
    expect(drawn).wont_include "no player"
    expect(drawn).wont_include "stroke-dasharray"
  end

  it "draws names which are not safe to put in an image" do
    image.context(name: %(Fish & <Chips> "to go"))

    expect(drawn).must_include "Fish &amp; &lt;Chips&gt; &quot;to go&quot;</text>"
  end

  it "draws a context with one role" do
    image.role(name: :only, type: :module, methods: [])

    expect(drawn).must_include %(<circle cx="360" cy="400" r="78")
  end

  it "writes to what it is given" do
    output = StringIO.new

    expect(image.write_to(output)).must_be_same_as image
    expect(output.string).must_equal drawn
  end
end
