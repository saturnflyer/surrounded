module Surrounded
  module Visualization
    # Writes what it is told as Markdown.
    #
    #   page = Surrounded::Visualization::Markdown.new
    #   Surrounded::Visualization.describe(MoneyTransfer, to: page)
    #   page.write_to($stdout)
    class Markdown < Template
      def initialize
        @name = nil
        @source = nil
        @roles = []
        @triggers = []
        @declared = []
        @players = []
        @runs = []
        @run = nil
      end

      def context(name:, source: nil)
        @name = name
        @source = source
        self
      end

      def role(name:, type:, methods:, behavior: nil)
        @roles << [name, type, methods]
        self
      end

      def trigger(name:)
        @triggers << name
        self
      end

      def declared_message(from:, to:, name:, via:, role_method:)
        @declared << [from, via, to, name]
        self
      end

      def player(role:, label:, class_name:, methods:, state:)
        (@run ? @run[:players] : @players) << [role, label, class_name]
        self
      end

      def run(trigger:)
        @run = {trigger: trigger, players: [], messages: [], leftovers: [], outcome: nil}
        self
      end

      def message(from:, to:, name:, arguments:)
        @run[:messages] << [from, to, name, arguments] if @run
        self
      end

      def leftover(role:, name:)
        @run[:leftovers] << [role, name] if @run
        self
      end

      def returned(value:)
        finish "Returned #{code(value)}."
      end

      def failed(error:, message:, role:)
        finish "Failed in #{sender(role)} with #{code(error)}: #{text(message)}"
      end

      def disallowed(message:)
        finish "Disallowed: #{text(message)}"
      end

      private

      def finish(outcome)
        if @run
          @run[:outcome] = outcome
          @runs << @run
          @run = nil
        end
        self
      end

      def render
        [
          heading,
          table("Roles", %w[Role Type Methods], role_rows),
          list("Triggers", @triggers.map { |name| code(name) }),
          table("Messages between roles", ["From", "In", "To", "Message"], declared_rows),
          table("Players", %w[Role Player Class], player_rows(@players)),
          *@runs.map { |run| run_section(run) }
        ].compact.join("\n\n") + "\n"
      end

      def heading
        lines = ["# #{text(@name || "Context")}"]
        lines << "Defined in #{code(@source)}." if @source
        lines.join("\n\n")
      end

      def role_rows
        @roles.map { |name, type, methods|
          [text(name), text(type ? type.to_s.tr("_", " ") : "none"), methods.map { |method| code_in_table(method) }.join(", ")]
        }
      end

      def declared_rows
        @declared.map { |from, via, to, name| [text(from), code_in_table(via), text(to), code_in_table(name)] }
      end

      def player_rows(players)
        players.map { |role, label, class_name| [text(role), text(label), code_in_table(class_name)] }
      end

      def run_section(run)
        steps = run[:messages].each_with_index.map { |(from, to, name, arguments), index|
          "#{index + 1}. #{sender(from)} tells #{text(to)} #{code("#{name}(#{arguments.join(", ")})")}"
        }
        left = run[:leftovers].map { |role, name| "#{code(name)} is still on the #{text(role)} player." }
        [
          "## Run of #{code(run[:trigger])}",
          table(nil, %w[Role Player Class], player_rows(run[:players])),
          (steps.join("\n") unless steps.empty?),
          run[:outcome],
          (left.join("\n") unless left.empty?)
        ].compact.join("\n\n")
      end

      def sender(role)
        (role == :context) ? text(@name || "The context") : text(role)
      end

      def table(title, headings, rows)
        return if rows.empty?

        lines = []
        lines << "## #{title}\n" if title
        lines << "| #{headings.join(" | ")} |"
        lines << "|#{headings.map { "---" }.join("|")}|"
        rows.each { |row| lines << "| #{row.join(" | ")} |" }
        lines.join("\n")
      end

      def list(title, items)
        return if items.empty?

        "## #{title}\n\n" + items.map { |item| "- #{item}" }.join("\n")
      end

      # Code is shown as it is written. A backslash inside of code is only a
      # backslash, so nothing is escaped.
      def code(value)
        "`#{value.to_s.tr("`", "'")}`"
      end

      # A bar would end the column of a table, even inside of code, so it is
      # escaped. A backslash is left alone. Inside of code a second backslash
      # would be shown beside the first.
      def code_in_table(value)
        code(value).gsub("|", "\\|")
      end

      # A backslash is escaped before a bar is escaped. Otherwise the
      # backslash written to escape a bar would be taken with a backslash
      # already in the value, and the bar would be left to end a column.
      def text(value)
        value.to_s.gsub("\\") { "\\\\" }.gsub("|") { "\\|" }
      end
    end
  end
end
