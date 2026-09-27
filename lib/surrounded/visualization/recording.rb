module Surrounded
  module Visualization
    # Runs a trigger and tells a template what happened.
    #
    # The trigger is run. Whatever the trigger changes will be changed.
    class Recording
      # @param context [Object] an instance of a context class
      # @param trigger [Symbol] the name of the trigger
      # @param names [Hash] labels for players, keyed by role
      # @yield [context] runs the trigger, when it needs arguments
      def initialize(context, trigger, names: {}, &action)
        @context = context
        @trigger = trigger
        @names = names
        @action = action || ->(subject) { subject.public_send(trigger) }
        @behaviors = {}
      end

      # @param template [Template]
      # @return [self]
      def tell(template)
        template.run(trigger: @trigger)
        Casting.new(@context, names: @names).tell(template)
        read_behaviors
        perform
        @messages.each { |message| template.message(**message) }
        leftovers.each { |leftover| template.leftover(**leftover) }
        @outcome.call(template)
        self
      end

      # Told by Behavior about each role in the context.
      #
      # @return [self]
      def role(name:, methods:, behavior: nil, **)
        @behaviors[name] = {methods: methods, behavior: behavior} if behavior
        self
      end

      private

      def role_map
        @context.send(:role_map)
      end

      def read_behaviors
        role_map.each do |role, behavior_name, _object|
          Behavior.new(@context.class, role, behavior_name).tell(self)
        end
      end

      def perform
        @messages = []
        senders = [:context]
        raised = []

        tracer = TracePoint.new(:call, :return, :raise) do |point|
          if point.event == :raise
            raised << [point.raised_exception, senders.last]
            next
          end

          role = role_receiving(point)
          next unless role

          if point.event == :call
            @messages << {from: senders.last, to: role, name: point.method_id, arguments: arguments(point)}
            senders.push(role)
          else
            senders.pop
          end
        end

        value = tracer.enable { @action.call(@context) }
        @outcome = ->(template) { template.returned(value: Inspection.of(value)) }
      rescue Surrounded::Context::AccessError => error
        @outcome = ->(template) { template.disallowed(message: Inspection.tidy(error.message)) }
      rescue => error
        _, role = raised.find { |exception, _| exception.equal?(error) }
        @outcome = ->(template) {
          template.failed(error: error.class.name.to_s, message: Inspection.tidy(error.message), role: role || :context)
        }
      end

      # The role whose method is being called, found by the behavior which
      # defines the method and then by the object receiving it.
      def role_receiving(point)
        roles = @behaviors.select { |_, details|
          details[:behavior].equal?(point.defined_class) && details[:methods].include?(point.method_id)
        }.keys
        return roles.first if roles.size < 2

        roles.find { |role| playing?(role, point.self) } || roles.first
      end

      def playing?(role, object)
        role_map.assigned_player(role).equal?(object) || role_map.current_player(role).equal?(object)
      end

      def arguments(point)
        point.parameters.filter_map { |_, name|
          next unless name && point.binding.local_variable_defined?(name)

          Inspection.of(point.binding.local_variable_get(name))
        }
      end

      def leftovers
        @behaviors.flat_map { |role, details|
          player = role_map.assigned_player(role)
          details[:methods].select { |name| player.respond_to?(name) }.map { |name| {role: role, name: name} }
        }
      end
    end
  end
end
