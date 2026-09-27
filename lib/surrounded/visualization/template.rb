module Surrounded
  module Visualization
    # The messages a template receives, and a place to begin your own.
    #
    # Every message returns the template. A template is told values and is
    # never asked for them. Inherit from this class and define the messages you
    # care about; the rest are accepted and ignored.
    #
    #   class RoleList < Surrounded::Visualization::Template
    #     def role(name:, **)
    #       names << name
    #       self
    #     end
    #
    #     private
    #
    #     def names
    #       @names ||= []
    #     end
    #
    #     def render
    #       names.join(", ")
    #     end
    #   end
    #
    # Messages arrive in this order:
    #
    # describe:: context, role for each role, trigger for each trigger,
    #            declared_message for each message found in the role methods
    # cast::     player for each role
    # record::   run, player for each role, message for each role method
    #            called, leftover for each role method left on a player, then
    #            one of returned, failed, or disallowed
    class Template
      MESSAGES = %i[
        context role trigger declared_message
        player
        run message leftover returned failed disallowed
      ].freeze

      # The context being shown.
      #
      # @param name [String] the name of the context class
      # @param source [String, nil] the file where the context is defined
      # @return [self]
      def context(name:, source: nil)
        self
      end

      # A role in the context.
      #
      # @param name [Symbol] the role
      # @param type [Symbol, nil] :module, :wrap, :interface, :delegate_class,
      #   :class, or nil when the role has no behavior
      # @param methods [Array<Symbol>] the role methods
      # @param behavior [Module, nil] the module or class holding the role methods
      # @return [self]
      def role(name:, type:, methods:, behavior: nil)
        self
      end

      # A trigger of the context.
      #
      # @param name [Symbol] the trigger
      # @return [self]
      def trigger(name:)
        self
      end

      # A message written in a role method and sent to another role.
      #
      # @param from [Symbol] the role sending the message
      # @param to [Symbol] the role receiving the message
      # @param name [Symbol] the message
      # @param via [Symbol] the role method which sends the message
      # @param role_method [Boolean] true when the message is a role method of
      #   the receiving role, false when it belongs to the player
      # @return [self]
      def declared_message(from:, to:, name:, via:, role_method:)
        self
      end

      # An object playing a role. Sent when casting, and after run for each
      # player in that run.
      #
      # @param role [Symbol] the role
      # @param label [String] what to call the player
      # @param class_name [String] the class of the player
      # @param methods [Array<Symbol>] the player's own public methods
      # @param state [Hash{String => String}] the player's instance variables
      # @return [self]
      def player(role:, label:, class_name:, methods:, state:)
        self
      end

      # A trigger is about to be shown. The messages which follow belong to
      # this run until returned, failed, or disallowed.
      #
      # @param trigger [Symbol] the trigger
      # @return [self]
      def run(trigger:)
        self
      end

      # A role method called during the run.
      #
      # @param from [Symbol] the role sending the message, or :context
      # @param to [Symbol] the role receiving the message
      # @param name [Symbol] the role method
      # @param arguments [Array<String>] the arguments, inspected
      # @return [self]
      def message(from:, to:, name:, arguments:)
        self
      end

      # A role method which a player still answers after the run.
      #
      # @param role [Symbol] the role
      # @param name [Symbol] the role method
      # @return [self]
      def leftover(role:, name:)
        self
      end

      # The run finished.
      #
      # @param value [String] what the trigger returned, inspected
      # @return [self]
      def returned(value:)
        self
      end

      # The run raised an error.
      #
      # @param error [String] the class of the error
      # @param message [String] the error message
      # @param role [Symbol] the role whose method was running, or :context
      # @return [self]
      def failed(error:, message:, role:)
        self
      end

      # The context did not allow the trigger with these players.
      #
      # @param message [String] the error message
      # @return [self]
      def disallowed(message:)
        self
      end

      # Put what the template has been told into an object which accepts <<,
      # such as a File, a StringIO, or $stdout.
      #
      # @param io [#<<]
      # @return [self]
      def write_to(io)
        io << render
        self
      end

      def to_s
        render
      end

      private

      def render
        ""
      end
    end
  end
end
