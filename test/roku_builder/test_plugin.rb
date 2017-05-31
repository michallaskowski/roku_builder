# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class PluginTest < Minitest::Test
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
        TestClass.parse_options(option_parser: nil, options: nil)
      end
    end
    def test_module_parse_options_success
      TestClass2.parse_options(option_parser: nil, options: nil)
    end
    def test_module_dependencies
      assert_equal Array, TestClass.dependencies.class
    end
    def test_module_dependencies
      assert_equal Array, TestClass2.dependencies.class
      assert_equal "test", TestClass2.dependencies[0]
    end
  end
  class TestClass
    extend Plugin
  end
  class TestClass2
    extend Plugin
    def self.commands
    end
    def self.parse_options(option_parser:, options:)
    end
    def self.dependencies
      ["test"]
    end
  end
end

