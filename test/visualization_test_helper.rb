require "test_helper"
require "open3"
require "rbconfig"
require "stringio"
require "surrounded/visualization"

module Visualized
  class Account
    include Surrounded

    attr_reader :name
    attr_accessor :balance

    def initialize(name, balance)
      @name = name
      @balance = balance
    end
  end

  class Ledger
    attr_reader :entries

    def initialize
      @entries = []
    end
  end

  class Clerk
    include Surrounded

    attr_reader :name

    def initialize(name)
      @name = name
    end
  end

  # One role of each type, and a trigger which may be disallowed.
  class MoneyTransfer
    extend Surrounded::Context

    protect_triggers

    initialize :depositor, :recipient, :ledger, :auditor

    trigger :transfer do
      depositor.withdraw_and_send(100)
    end

    trigger :audit do
      auditor.review
    end

    trigger :send_amount do |amount, note: nil|
      depositor.withdraw_and_send(amount)
    end

    disallow :transfer do
      depositor.balance < 100
    end

    role :depositor do
      def withdraw_and_send(amount)
        self.balance -= amount
        recipient.receive(amount)
        ledger.record(name, amount)
      end
    end

    role :recipient, :wrap do
      def receive(amount)
        self.balance += amount
      end
    end

    role :ledger, :interface do
      def record(who, amount)
        entries << [who, amount]
        entries.size
      end
    end

    delegate_class :auditor, "Visualized::Clerk" do
      def review
        ledger.entries.size
      end
    end
  end

  # A role with no behavior and a collection of role players.
  class Meeting
    extend Surrounded::Context

    initialize :leader, :members, :room

    trigger :greet do
      members.map { |member| member.greet }
    end

    role :member do
      def greet
        "Hello #{leader.name}, I am #{name}"
      end
    end
  end

  # A template which keeps each message it is told.
  class Spy < Surrounded::Visualization::Template
    attr_reader :received

    def initialize
      @received = []
    end

    Surrounded::Visualization::Template::MESSAGES.each do |message|
      define_method(message) do |**details|
        @received << [message, details]
        self
      end
    end

    def named(message)
      received.select { |name, _| name == message }.map(&:last)
    end

    def names
      received.map(&:first)
    end
  end

  module Players
    def self.transfer(depositor: Account.new("Alice", 500), recipient: Account.new("Bob", 50), ledger: Ledger.new, auditor: Clerk.new("Casey"))
      MoneyTransfer.new(depositor: depositor, recipient: recipient, ledger: ledger, auditor: auditor)
    end
  end

  # Run Ruby apart from the tests, where the visualization is already loaded.
  module Apart
    LIB = File.expand_path("../lib", __dir__)
    FIXTURES = File.expand_path("fixtures/visualization", __dir__)

    def self.run(script, prism: nil)
      paths = [("-I#{File.join(FIXTURES, prism)}" if prism), "-I#{LIB}"].compact
      Open3.capture3(RbConfig.ruby, *paths, "-e", script)
    end
  end
end
