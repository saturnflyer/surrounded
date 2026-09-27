require "prism"

module Surrounded
  module Visualization
    # Finds the messages which role methods send to other roles by reading the
    # source of the role methods.
    #
    # Tell this about the roles, then have it tell a template what it found.
    #
    #   declared = DeclaredMessages.new
    #   Roles.new(MoneyTransfer).tell(declared)
    #   declared.tell(template)
    #
    # Reading the source needs Prism. Surrounded::Visualization uses
    # NoDeclaredMessages in place of this when Prism cannot be used.
    class DeclaredMessages
      def initialize
        @roles = {}
        @parsed = {}
      end

      # @return [self]
      def role(name:, methods:, behavior: nil, **)
        @roles[name] = {methods: methods, behavior: behavior}
        self
      end

      # @param template [#declared_message]
      # @return [self]
      def tell(template)
        @roles.each do |role, details|
          definitions(details).each do |via, definition|
            calls_in(definition).each do |call|
              receiver = call.receiver
              next unless receiver.is_a?(Prism::CallNode) && receiver.receiver.nil? && @roles.key?(receiver.name)

              template.declared_message(
                from: role,
                to: receiver.name,
                name: call.name,
                via: via,
                role_method: @roles[receiver.name][:methods].include?(call.name)
              )
            end
          end
        end
        self
      end

      private

      def definitions(details)
        return [] unless details[:behavior]

        details[:methods].filter_map { |name|
          file, line = details[:behavior].instance_method(name).source_location
          next unless file && File.file?(file)

          definition = definition_in(parsed(file), name, line)
          [name, definition] if definition
        }
      end

      def parsed(file)
        @parsed[file] ||= Prism.parse_file(file).value
      end

      def definition_in(node, name, line)
        return node if node.is_a?(Prism::DefNode) && node.name == name && node.location.start_line == line

        node.compact_child_nodes.each do |child|
          found = definition_in(child, name, line)
          return found if found
        end
        nil
      end

      def calls_in(node)
        found = node.is_a?(Prism::CallNode) ? [node] : []
        found + node.compact_child_nodes.flat_map { |child| calls_in(child) }
      end
    end
  end
end
