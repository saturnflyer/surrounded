require "json"

module Surrounded
  module Visualization
    # Writes what it is told as a page to open in a browser. Players are
    # dragged into and out of the roles of the context, and the recorded runs
    # are played back for the players in the roles.
    #
    # Describe the context, then record a run for each cast of players you
    # want to be able to play.
    #
    #   page = Surrounded::Visualization::Html.new
    #   Surrounded::Visualization
    #     .describe(MoneyTransfer, to: page)
    #     .record(transfer, :send_money, to: page)
    #   File.open("money_transfer.html", "w") { |file| page.write_to(file) }
    #
    # The page needs nothing from the network.
    class Html < Template
      PAGE = File.expand_path("templates/interactive.html", __dir__)
      DATA = "/*__CONTEXT_DATA__*/null"

      # @param page [String] the page to fill, which marks where the data
      #   belongs with Html::DATA
      def initialize(page: File.read(PAGE))
        @page = page
        @name = nil
        @source = nil
        @roles = []
        @triggers = []
        @declared = []
        @objects = {}
        @cast = {}
        @runs = []
        @run = nil
      end

      def context(name:, source: nil)
        @name = name
        @source = source
        self
      end

      def role(name:, type:, methods:, behavior: nil)
        @roles << {name: name, type: type, methods: methods, left_behind: []}
        self
      end

      def trigger(name:)
        @triggers << name
        self
      end

      def declared_message(from:, to:, name:, via:, role_method:)
        @declared << {from: from, to: to, method: name, via: via, role_method: role_method}
        self
      end

      def player(role:, label:, class_name:, methods:, state:)
        key = key_for(label, class_name)
        @objects[key] ||= {key: key, label: label, class: class_name, methods: methods, state: state}
        (@run ? @run[:cast] : @cast)[role] = key
        self
      end

      def run(trigger:)
        @run = {trigger: trigger, cast: {}, messages: [], result: nil, error: nil, allowed: true}
        self
      end

      def message(from:, to:, name:, arguments:)
        @run[:messages] << {from: from, to: to, method: name, args: arguments} if @run
        self
      end

      def leftover(role:, name:)
        found = @roles.find { |known| known[:name] == role }
        found[:left_behind] << {method: name} if found && found[:left_behind].none? { |left| left[:method] == name }
        self
      end

      def returned(value:)
        finish(result: value)
      end

      def failed(error:, message:, role:)
        finish(error: {class: error, message: message, in: role})
      end

      def disallowed(message:)
        finish(allowed: false, error: {class: "AccessError", message: message, in: :context})
      end

      private

      def finish(outcome)
        if @run
          @runs << @run.merge(outcome)
          @run = nil
        end
        self
      end

      # Players are known to the page by their label. Players of different
      # classes with the same label are told apart by their class.
      def key_for(label, class_name)
        key = label.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
        key = "player" if key.empty?
        taken = @objects[key]
        (taken && taken[:class] != class_name) ? "#{key}-#{class_name.to_s.downcase.gsub(/[^a-z0-9]+/, "-")}" : key
      end

      def scenarios
        @runs.each_with_object({}) { |run, found|
          cast = @roles.map { |role| run[:cast][role[:name]] }.join(",")
          (found[cast] ||= {})[run[:trigger]] = run.slice(:messages, :result, :error, :allowed)
        }
      end

      def default_cast
        cast = @cast.empty? ? @runs.first&.fetch(:cast) : @cast
        cast unless cast.nil? || cast.empty?
      end

      def document
        {
          context: @name,
          source: @source,
          ruby: RUBY_VERSION,
          surrounded: Surrounded.version,
          roles: @roles,
          triggers: @triggers,
          objects: @objects.values,
          default_cast: default_cast,
          static_messages: @declared,
          scenarios: scenarios
        }
      end

      def render
        data = JSON.generate(document).gsub("</", "<\\/")
        @page.sub(DATA) { data }
      end
    end
  end
end
