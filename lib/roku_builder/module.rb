# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder

  # mixin for plugins
  module Plugin

    def commands
      raise ImplementationError, "commands method not implemented"
      #[
      #  {
      #   name: :command_name,
      #   device: true || false,
      #   source: true || false,
      #   exclude: true || false
      #  }
      #]
    end

    def parse_options(option_parser:, options:)
      raise ImplementationError, "parse_options method not implemented"
    end

    def dependencies
      []
    end
  end
end