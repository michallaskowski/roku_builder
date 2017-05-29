# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder

  # Super class for modules
  # This class defines a common initializer and allows subclasses
  # to define their own secondary initializer
  module Module

    def commands
      raise ImplementationError, "commands method not implemented"
      #[
      #  {
      #   name: "command_name",
      #   device: true || false,
      #   source: true || false,
      #   exclude: true || false
      #  }
      #]
    end

    def parse_options(option_parser:)
      raise ImplementationError, "parse_options method not implemented"
    end

  end
end
