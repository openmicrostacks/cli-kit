require 'cli/kit'

module CLI
  module Kit
    class CommandRegistry
      attr_reader :commands, :aliases

      module NullContextualResolver
        def self.command_names
          []
        end

        def self.aliases
          {}
        end

        def self.command_class(_name)
          nil
        end
      end

      def initialize(default:, contextual_resolver: NullContextualResolver)
        @commands = {}
        @aliases  = {}
        @default = default
        @contextual_resolver = contextual_resolver
      end

      def resolved_commands
        @commands.each_with_object({}) do |(k, v), a|
          a[k] = resolve_class(v)
        end
      end

      def add(const, name)
        commands[name] = const
      end

      def lookup_command(name)
        name = @default if name.to_s.empty?
        resolve_command(name)
      end

      def add_alias(from, to)
        aliases[from] = to unless aliases[from]
      end

      def resolve_command(name)
        resolve_global_command(name) || \
          resolve_contextual_command(name) || \
          [nil, resolve_alias(name)]
      end

      def resolve_alias(name)
        aliases[name] || @contextual_resolver.aliases.fetch(name, name)
      end

      def resolve_global_command(name)
        name = resolve_alias(name)
        klass = resolve_class(commands.fetch(name, ""))
        return nil unless klass.defined? # (BaseCommand)
        [klass, name]
      rescue NameError
        nil
      end

      def resolve_contextual_command(name)
        name = resolve_alias(name)
        found = @contextual_resolver.command_names.include?(name)
        return nil unless found
        [@contextual_resolver.command_class(name), name]
      end

      def command_names
        @contextual_resolver.command_names + commands.keys
      end

      def exist?(name)
        !resolve_command(name).first.nil?
      end

      private

      def resolve_class(class_or_proc)
        if class_or_proc.is_a?(Class)
          class_or_proc
        else
          class_or_proc.call
        end
      end
    end
  end
end
