module Surrounded
  module Visualization
    # Draws what it is told as an SVG image: the context as a circle, the
    # roles inside it, the players in their roles, and the messages between
    # roles. Runs are not drawn.
    #
    #   image = Surrounded::Visualization::Svg.new
    #   Surrounded::Visualization.describe(MoneyTransfer, to: image)
    #   File.open("money_transfer.svg", "w") { |file| image.write_to(file) }
    class Svg < Template
      WIDTH = 720
      HEIGHT = 780
      CENTER = [360, 400].freeze
      WALL = 300
      RING = 188
      HUES = %w[#2B4BEE #D42A66 #0B8457 #C25E00 #6F3BE0 #087F9B].freeze
      INK = "#11131A"
      MUTED = "#565C6B"
      SANS = "system-ui, -apple-system, 'Segoe UI', sans-serif"
      MONO = "ui-monospace, 'SF Mono', Menlo, Consolas, monospace"

      def initialize
        @name = "Context"
        @roles = []
        @triggers = []
        @declared = Hash.new { |hash, key| hash[key] = [] }
        @players = {}
      end

      def context(name:, source: nil)
        @name = name
        self
      end

      def role(name:, type:, methods:, behavior: nil)
        @roles << {name: name, type: type, methods: methods}
        self
      end

      def trigger(name:)
        @triggers << name
        self
      end

      def declared_message(from:, to:, name:, via:, role_method:)
        @declared[[from, to]] << name unless from == to || @declared[[from, to]].include?(name)
        self
      end

      def player(role:, label:, class_name:, methods:, state:)
        @players[role] ||= "#{label} (#{class_name})"
        self
      end

      private

      def render
        <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{WIDTH} #{HEIGHT}" width="#{WIDTH}" height="#{HEIGHT}" role="img" aria-label="#{escape(@name)} context">
            <defs>
              <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
                <path d="M 0 0 L 10 5 L 0 10 z" fill="#{INK}"/>
              </marker>
            </defs>
            <rect width="#{WIDTH}" height="#{HEIGHT}" fill="#E4E7ED"/>
            <text x="#{CENTER[0]}" y="44" text-anchor="middle" font-family="#{SANS}" font-size="26" font-weight="700" fill="#{INK}">#{escape(@name)}</text>
            #{triggers}
            <circle cx="#{CENTER[0]}" cy="#{CENTER[1]}" r="#{WALL}" fill="#FFFFFF" stroke="#{INK}" stroke-width="14"/>
            #{[messages, roles].flatten.join("\n  ")}
          </svg>
        SVG
      end

      def triggers
        return "" if @triggers.empty?

        %(<text x="#{CENTER[0]}" y="70" text-anchor="middle" font-family="#{MONO}" font-size="13" fill="#{MUTED}">triggers: #{escape(@triggers.join(", "))}</text>)
      end

      def radius
        return 78 if @roles.size < 2

        [78, (Math::PI * RING / @roles.size) - 8].min.round
      end

      def position(role_name)
        index = @roles.index { |role| role[:name] == role_name }
        return unless index
        return CENTER if @roles.size == 1

        angle = (-180 + (index + 0.5) * 360.0 / @roles.size) * Math::PI / 180
        [CENTER[0] + RING * Math.cos(angle), CENTER[1] + RING * Math.sin(angle)]
      end

      def roles
        @roles.each_with_index.map { |role, index|
          x, y = position(role[:name])
          hue = HUES[index % HUES.size]
          player = @players[role[:name]]
          lines = [
            [role[:name], SANS, 15, 700, hue],
            [player || "no player", SANS, 12, 400, player ? INK : MUTED],
            *role[:methods].first(4).map { |method| [method, MONO, 11, 400, INK] }
          ]
          lines << ["and #{role[:methods].size - 4} more", SANS, 11, 400, MUTED] if role[:methods].size > 4
          top = y - (lines.size * 16) / 2.0
          text = lines.each_with_index.map { |(content, family, size, weight, fill), line|
            %(<text x="#{fmt(x)}" y="#{fmt(top + (line + 0.75) * 16)}" text-anchor="middle" font-family="#{family}" font-size="#{size}" font-weight="#{weight}" fill="#{fill}">#{escape(content)}</text>)
          }
          dash = player ? "" : %( stroke-dasharray="2 10" stroke-linecap="round")
          [
            %(<circle cx="#{fmt(x)}" cy="#{fmt(y)}" r="#{radius}" fill="#FFFFFF" stroke="#{hue}" stroke-width="5"#{dash}/>),
            *text
          ].join("\n  ")
        }
      end

      def messages
        @declared.filter_map { |(from, to), names|
          start, finish = position(from), position(to)
          next unless start && finish

          length = Math.hypot(finish[0] - start[0], finish[1] - start[1])
          next if length <= radius * 2

          unit = [(finish[0] - start[0]) / length, (finish[1] - start[1]) / length]
          # messages in both directions are drawn side by side
          shift = @declared.key?([to, from]) ? 9 : 0
          offset = [-unit[1] * shift, unit[0] * shift]
          x1 = start[0] + unit[0] * (radius + 6) + offset[0]
          y1 = start[1] + unit[1] * (radius + 6) + offset[1]
          x2 = finish[0] - unit[0] * (radius + 9) + offset[0]
          y2 = finish[1] - unit[1] * (radius + 9) + offset[1]
          [
            %(<line x1="#{fmt(x1)}" y1="#{fmt(y1)}" x2="#{fmt(x2)}" y2="#{fmt(y2)}" stroke="#{INK}" stroke-width="2" marker-end="url(#arrow)"/>),
            %(<text x="#{fmt((x1 + x2) / 2)}" y="#{fmt((y1 + y2) / 2 - 7 + offset[1])}" text-anchor="middle" font-family="#{MONO}" font-size="11" fill="#{INK}" stroke="#FFFFFF" stroke-width="4" paint-order="stroke">#{escape(names.join(", "))}</text>)
          ].join("\n  ")
        }
      end

      def fmt(number)
        number.round(1).to_s.sub(/\.0\z/, "")
      end

      def escape(value)
        value.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub('"', "&quot;")
      end
    end
  end
end
