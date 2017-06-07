# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class OptionsTest < Minitest::Test
    def setup
      RokuBuilder.class_variable_set(:@@plugins, [])
    end
    def teardown
      RokuBuilder.class_variable_set(:@@plugins, [])
    end
    def test_options_initialize_no_params
      count = 0
      parse_stub = lambda{ count+= 1; {validate: true} }
      options = Options.allocate
      options.stub(:parse, parse_stub) do
        options.send(:initialize)
      end
      assert_equal 1, count
    end
    def test_options_initialize_params
      count = 0
      parse_stub = lambda{ count+= 1; {validate: true} }
      options = Options.allocate
      options.stub(:parse, parse_stub) do
        options.send(:initialize, {options: {validate: true}})
      end
      assert_equal 0, count
    end
    def test_options_parse
      parser = Minitest::Mock.new()
      options_hash = {}
      options = Options.allocate
      parser.expect(:banner=, nil, [String])
      parser.expect(:parse!, nil)
      OptionParser.stub(:new, parser) do
        options.stub(:validate_parser, nil) do
          options_hash = options.send(:parse)
        end
      end
      parser.verify
    end
    def test_options_parse_validate_options_good
      Array.class_eval { alias_method :each_option, :each  }
      parser = Minitest::Mock.new()
      options = Options.allocate
      parser.expect(:instance_variable_get, build_stack, [:@stack])
      parser.expect(:banner=, nil, [String])
      parser.expect(:parse!, nil)
      OptionParser.stub(:new, parser) do
        options.send(:parse)
      end
      parser.verify
      Array.class_eval { remove_method :each_option  }
    end
    def test_options_parse_validate_options_bad
      Array.class_eval { alias_method :each_option, :each  }
      parser = Minitest::Mock.new()
      options = Options.allocate
      parser.expect(:banner=, nil, [String])
      parser.expect(:instance_variable_get, build_stack(false), [:@stack])

      OptionParser.stub(:new, parser) do
        assert_raises(ImplementationError) do
          options.send(:parse)
        end
      end
      parser.verify
      Array.class_eval { remove_method :each_option  }
    end
    def build_stack(good = true)
      optionsA = Minitest::Mock.new()
      optionsB = Minitest::Mock.new()
      list = [optionsA, optionsB]
      stack = [list]
      3.times do
        optionsA.expect(:short, [ "a" ])
        optionsA.expect(:long, [ "aOption" ])
        if good
          optionsB.expect(:short, [ "b" ])
          optionsB.expect(:long, ["bOption" ])
        else
          optionsB.expect(:short, [ "a" ])
          optionsB.expect(:long, [ "aOption" ])
        end
      end
      stack
    end
    def test_options_validate_extra_commands
      options = {
        configure: true,
        validate: true
      }
      assert_raises InvalidOptions do
        build_options(options)
      end
    end
    def test_options_validate_no_commands
      options = {}
      assert_raises InvalidOptions do
        build_options(options)
      end
    end
    def test_options_validate_extra_sources_sideload
      options = {
        validate: true,
        working: true,
        current: true
      }
      assert_raises InvalidOptions do
        build_options(options)
      end
    end
    def test_options_validate_extra_sources_package
      options = {
        validate: true,
        in: "",
        stage: "production"
      }
      assert_raises InvalidOptions do
        build_options(options)
      end
    end
    def test_options_exclude_command
      options = build_options({
        validate:true,
      })
      options.define_singleton_method(:exclude_commands) {[:validate]}
      assert options.exclude_command?
    end
    def test_options_exclude_command_false
      options = build_options({
        validate:true,
      })
      refute options.exclude_command?
    end
    def test_options_source_command
      options = build_options({
        validate:true,
      })
      options.define_singleton_method(:source_commands) {[:validate]}
      assert options.source_command?
    end
    def test_options_source_commandfalse
      options = build_options({
        validate: true,
      })
      refute options.source_command?
    end
    def test_options_command
      options = build_options({
        validate: true,
      })
      assert_equal :validate, options.command
    end
    def test_options_device_command_true
      options = build_options({
        validate: true,
      })
      options.define_singleton_method(:device_commands) {[:validate]}
      assert options.device_command?
    end
    def test_options_device_command_false
      options = build_options({
        validate: true,
      })
      refute options.device_command?
    end
    def test_options_has_source_false
      options = build_options({
        validate: true,
      })
      refute options.has_source?
    end
    def test_options_has_source_true
      options = build_options({
        validate: true,
        working: true
      })
      assert options.has_source?
    end
  end
end
