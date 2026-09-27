require "visualization_test_helper"

describe Surrounded::Visualization do
  let(:spy) { Visualized::Spy.new }

  describe "loading" do
    it "is left out when surrounded is required" do
      output, = Visualized::Apart.run(%(require "surrounded"; print defined?(Surrounded::Visualization).inspect))

      expect(output).must_equal "nil"
    end

    it "is loaded when required by name" do
      output, warnings = Visualized::Apart.run(%(require "surrounded/visualization"; print Surrounded::Visualization::MESSAGES_IN_SOURCE))

      expect(output).must_equal "Surrounded::Visualization::DeclaredMessages"
      expect(warnings).must_equal ""
    end

    it "warns when Prism is missing and leaves surrounded working" do
      script = <<~'SCRIPT'
        require "surrounded/visualization"
        class Pairing
          extend Surrounded::Context
          initialize :first, :second
          trigger(:go) { first.start }
          role(:first) { def start = second.finish }
          role(:second) { def finish = "finished" }
        end
        Person = Struct.new(:name) { include Surrounded }
        class Outline < Surrounded::Visualization::Template
          def role(name:, methods:, **)
            puts "role #{name} with #{methods.join}"
            self
          end
        end
        Surrounded::Visualization.describe(Pairing, to: Outline.new)
        print Pairing.new(first: Person.new("a"), second: Person.new("b")).go
      SCRIPT
      output, warnings, status = Visualized::Apart.run(script, prism: "without_prism")

      expect(status.success?).must_equal true
      expect(warnings).must_match(/Surrounded::Visualization will not show the messages written in role methods/)
      expect(warnings).must_match(/Prism could not be loaded with Ruby #{Regexp.escape(RUBY_VERSION)}/o)
      expect(output).must_equal "role first with start\nrole second with finish\nfinished"
    end

    it "warns when Prism cannot do what is needed" do
      output, warnings, status = Visualized::Apart.run(
        %(require "surrounded/visualization"; print Surrounded::Visualization::MESSAGES_IN_SOURCE),
        prism: "incompatible_prism"
      )

      expect(status.success?).must_equal true
      expect(output).must_equal "Surrounded::Visualization::NoDeclaredMessages"
      expect(warnings).must_match(/Prism 0\.1\.0 cannot do what is needed\. Use Prism 0\.19 or later\./)
    end
  end

  describe ".describe" do
    before do
      @result = Surrounded::Visualization.describe(Visualized::MoneyTransfer, to: spy)
    end

    it "returns the visualization" do
      expect(@result).must_equal Surrounded::Visualization
    end

    it "tells the template the context and where it is defined" do
      expect(spy.named(:context)).must_equal [
        {name: "Visualized::MoneyTransfer", source: "test/visualization_test_helper.rb"}
      ]
    end

    it "tells the template each role with its type and methods" do
      roles = spy.named(:role).map { |role| role.slice(:name, :type, :methods) }

      expect(roles).must_equal [
        {name: :depositor, type: :module, methods: [:withdraw_and_send]},
        {name: :recipient, type: :wrap, methods: [:receive]},
        {name: :ledger, type: :interface, methods: [:record]},
        {name: :auditor, type: :delegate_class, methods: [:review]}
      ]
    end

    it "leaves out the methods a delegate class takes from the class it wraps" do
      script = <<~'SCRIPT'
        # A public method on Kernel, as some versions of Bundler make of Kernel#gem.
        module Kernel
          def shout
            "loud"
          end
        end
        require "surrounded/visualization"

        class Speaker
          include Surrounded
          def name = "speaker"
        end

        class Announcement
          extend Surrounded::Context
          initialize :announcer
          trigger(:announce) { announcer.begin_speaking }
          delegate_class :announcer, "Speaker" do
            def begin_speaking
              "begun"
            end
          end
        end

        class Outline < Surrounded::Visualization::Template
          def role(name:, methods:, **)
            print "#{name}: #{methods.join(", ")}"
            self
          end
        end
        Surrounded::Visualization.describe(Announcement, to: Outline.new)
      SCRIPT
      output, = Visualized::Apart.run(script)

      expect(output).must_equal "announcer: begin_speaking"
    end

    it "tells the template each trigger" do
      expect(spy.named(:trigger)).must_equal [{name: :transfer}, {name: :audit}, {name: :send_amount}]
    end

    it "tells the template the messages written in role methods" do
      expect(spy.named(:declared_message)).must_equal [
        {from: :depositor, to: :recipient, name: :receive, via: :withdraw_and_send, role_method: true},
        {from: :depositor, to: :ledger, name: :record, via: :withdraw_and_send, role_method: true},
        {from: :auditor, to: :ledger, name: :entries, via: :review, role_method: false}
      ]
    end

    it "tells the template about roles which have no behavior" do
      Surrounded::Visualization.describe(Visualized::Meeting, to: spy)
      roles = spy.named(:role).last(3).map { |role| role.slice(:name, :type, :methods) }

      expect(roles).must_equal [
        {name: :leader, type: nil, methods: []},
        {name: :members, type: nil, methods: []},
        {name: :room, type: nil, methods: []}
      ]
    end
  end

  describe ".cast" do
    let(:context) { Visualized::Players.transfer }

    it "returns the visualization" do
      expect(Surrounded::Visualization.cast(context, to: spy)).must_equal Surrounded::Visualization
    end

    it "tells the template who plays each role" do
      Surrounded::Visualization.cast(context, to: spy)
      players = spy.named(:player).map { |player| player.slice(:role, :label, :class_name) }

      expect(players).must_equal [
        {role: :depositor, label: "Alice", class_name: "Visualized::Account"},
        {role: :recipient, label: "Bob", class_name: "Visualized::Account"},
        {role: :ledger, label: "Visualized::Ledger", class_name: "Visualized::Ledger"},
        {role: :auditor, label: "Casey", class_name: "Visualized::Clerk"}
      ]
    end

    it "tells the template what each player can do and what it holds" do
      Surrounded::Visualization.cast(context, to: spy)
      alice = spy.named(:player).first

      expect(alice[:methods]).must_equal [:balance, :balance=, :name]
      expect(alice[:state]).must_equal({"name" => '"Alice"', "balance" => "500"})
    end

    it "uses the names it is given" do
      Surrounded::Visualization.cast(context, to: spy, names: {ledger: "The book"})

      expect(spy.named(:player).map { |player| player[:label] }).must_equal ["Alice", "Bob", "The book", "Casey"]
    end
  end
end

describe Surrounded::Visualization::Template do
  let(:template) { Surrounded::Visualization::Template.new }

  it "returns itself from every message" do
    sent = {
      context: {name: "Transfer", source: nil},
      role: {name: :sender, type: :module, methods: []},
      trigger: {name: :send_money},
      declared_message: {from: :sender, to: :receiver, name: :receive, via: :send_money, role_method: true},
      player: {role: :sender, label: "Alice", class_name: "Account", methods: [], state: {}},
      run: {trigger: :send_money},
      message: {from: :context, to: :sender, name: :send_money, arguments: []},
      leftover: {role: :sender, name: :send_money},
      returned: {value: "1"},
      failed: {error: "NameError", message: "missing", role: :sender},
      disallowed: {message: "not allowed"}
    }

    expect(sent.keys).must_equal Surrounded::Visualization::Template::MESSAGES
    sent.each do |message, details|
      expect(template.public_send(message, **details)).must_be_same_as template
    end
  end

  it "writes to what it is given and returns itself" do
    output = StringIO.new

    expect(template.write_to(output)).must_be_same_as template
    expect(output.string).must_equal ""
  end

  it "lets a template take only the messages it wants" do
    role_list = Class.new(Surrounded::Visualization::Template) {
      def role(name:, **)
        names << name
        self
      end

      private

      def names
        @names ||= []
      end

      def render
        names.join(", ")
      end
    }.new
    Surrounded::Visualization.describe(Visualized::MoneyTransfer, to: role_list)

    expect(role_list.to_s).must_equal "depositor, recipient, ledger, auditor"
  end
end

describe Surrounded::Visualization::NoDeclaredMessages do
  it "listens to the roles and tells a template nothing" do
    spy = Visualized::Spy.new
    silent = Surrounded::Visualization::NoDeclaredMessages.new
    Surrounded::Visualization::Roles.new(Visualized::MoneyTransfer).tell(silent)

    expect(silent.tell(spy)).must_be_same_as silent
    expect(spy.received).must_equal []
  end
end
