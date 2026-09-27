require "surrounded"
require "surrounded/visualization/template"
require "surrounded/visualization/behavior"
require "surrounded/visualization/roles"
require "surrounded/visualization/no_declared_messages"
require "surrounded/visualization/casting"
require "surrounded/visualization/recording"

module Surrounded
  # Show what a context is made of and what happens inside it.
  #
  # This is not loaded with Surrounded. Require it where you need it:
  #
  #   require "surrounded/visualization"
  #
  # Each method here reads a context and tells a template what it found. The
  # template decides where each value belongs. Every method returns
  # Surrounded::Visualization so the calls may be chained.
  #
  #   Surrounded::Visualization
  #     .describe(MoneyTransfer, to: template)
  #     .cast(transfer, to: template)
  #     .record(transfer, :send_money, to: template)
  #   template.write_to($stdout)
  #
  # Any object which answers the messages in
  # Surrounded::Visualization::Template may be used as a template.
  module Visualization
    # Reading the messages written in role methods needs Prism. When Prism is
    # missing, or cannot do what is needed, say so and carry on without it.
    # Nothing else in Surrounded depends on Prism.
    prism_problem = begin
      require "prism"
      capable = Prism.respond_to?(:parse_file) &&
        defined?(Prism::DefNode) &&
        defined?(Prism::CallNode) &&
        [Prism::DefNode, Prism::CallNode].all? { |node|
          node.method_defined?(:compact_child_nodes) && node.method_defined?(:name)
        }
      unless capable
        version = defined?(Prism::VERSION) ? Prism::VERSION : "in use"
        "Prism #{version} cannot do what is needed. Use Prism 0.19 or later."
      end
    rescue LoadError
      "Prism could not be loaded with Ruby #{RUBY_VERSION}. " \
        "Prism comes with Ruby 3.3 and later, or may be added as a gem."
    end

    if prism_problem
      warn "Surrounded::Visualization will not show the messages written in role methods. " \
        "#{prism_problem} Everything else in Surrounded works as usual."
      MESSAGES_IN_SOURCE = NoDeclaredMessages
    else
      require "surrounded/visualization/declared_messages"
      MESSAGES_IN_SOURCE = DeclaredMessages
    end

    class << self
      # Tell a template about a context class: its name, roles, triggers, and
      # the messages its role methods send to other roles.
      #
      # @param context_class [Class] a class extended with Surrounded::Context
      # @param to [Template] the template to tell
      # @return [Surrounded::Visualization]
      def describe(context_class, to:)
        to.context(name: context_class.name.to_s, source: source_of(context_class))
        declared = MESSAGES_IN_SOURCE.new
        Roles.new(context_class).tell(to).tell(declared)
        context_class.triggers.each { |name| to.trigger(name: name) }
        declared.tell(to)
        self
      end

      # Tell a template which object plays each role in a context.
      #
      # @param context [Object] an instance of a context class
      # @param to [Template] the template to tell
      # @param names [Hash] labels for players, keyed by role, to use in place
      #   of the label found from the object
      # @return [Surrounded::Visualization]
      def cast(context, to:, names: {})
        Casting.new(context, names: names).tell(to)
        self
      end

      # Run a trigger and tell a template what happened: the players, each role
      # method called, anything left on the players, and how the run ended.
      #
      # This runs the trigger. Whatever the trigger changes will be changed.
      #
      # Give a block to run the trigger with arguments.
      #
      #   Surrounded::Visualization.record(transfer, :send_money, to: page) do |context|
      #     context.send_money(100)
      #   end
      #
      # @param context [Object] an instance of a context class
      # @param trigger [Symbol] the name of the trigger
      # @param to [Template] the template to tell
      # @param names [Hash] labels for players, keyed by role
      # @return [Surrounded::Visualization]
      def record(context, trigger, to:, names: {}, &action)
        Recording.new(context, trigger, names: names, &action).tell(to)
        self
      end

      private

      def source_of(context_class)
        return unless context_class.name

        file, = Object.const_source_location(context_class.name)
        return unless file

        file.delete_prefix("#{Dir.pwd}/")
      end
    end
  end
end
