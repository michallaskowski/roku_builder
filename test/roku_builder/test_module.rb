# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class ModuleTest < Minitest::Test
    def test_module_commands_fail
      assert_raises ImplementationError do
        TestClass.commands
      end
    end
    def test_module_commands_success
      TestClass2.commands
    end
    def test_module_parse_options_fail
      assert_raises ImplementationError do
        TestClass.parse_options(option_parser: nil)
      end
    end
    def test_module_parse_options_success
      TestClass2.parse_options(option_parser: nil)
    end
  end
  class TestClass
    extend Module
  end
  class TestClass2
    extend Module
    def self.commands
    end
    def self.parse_options(option_parser:)
    end
  end
end

