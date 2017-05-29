# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class OptionsTest < Minitest::Test
    def test_options_initialize_no_params
      count = 0
      parse_stub = lambda{ count+= 1; {screens: true} }
      options = Options.allocate
      options.stub(:parse, parse_stub) do
        options.send(:initialize)
      end
      assert_equal 1, count
    end
    def test_options_initialize_params
      count = 0
      parse_stub = lambda{ count+= 1; {screens: true} }
      options = Options.allocate
      options.stub(:parse, parse_stub) do
        options.send(:initialize, {options: {screens: true}})
      end
      assert_equal 0, count
    end
    def test_options_parse
      parser = Minitest::Mock.new()
      options = Options.allocate
      parser.expect(:parse!, nil)
      options.stub(:build_parser, parser) do
        options.stub(:validate_parser, nil) do
          options.send(:parse)
        end
      end
      parser.verify
    end
    def test_options_parse_validate_options_good
      Array.class_eval { alias_method :each_option, :each  }
      parser = Minitest::Mock.new()
      options = Options.allocate
      parser.expect(:instance_variable_get, build_stack, [:@stack])

      parser.expect(:parse!, nil)
      options.stub(:build_parser, parser) do
        options.send(:parse)
      end
      parser.verify
      Array.class_eval { remove_method :each_option  }
    end
    def test_options_parse_validate_options_good
      Array.class_eval { alias_method :each_option, :each  }
      parser = Minitest::Mock.new()
      options = Options.allocate
      parser.expect(:instance_variable_get, build_stack(false), [:@stack])

      options.stub(:build_parser, parser) do
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
      2.times do
        optionsA.expect(:short, "a")
        optionsA.expect(:long, "aOption")
        if good
          optionsB.expect(:short, "b")
          optionsB.expect(:long, "bOption")
        else
          optionsB.expect(:short, "a")
          optionsB.expect(:long, "aOption")
        end
      end
      stack
    end
    def test_options_validate_extra_commands
      options = {
        sideload: true,
        package: true
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
        sideload: true,
        working: true,
        current: true
      }
      assert_raises InvalidOptions do
        build_options(options)
      end
    end
    def test_options_validate_working
      options = {
        sideload: true,
        working: true
      }
      build_options(options)
    end
    def test_options_validate_no_source
      options = {
        package: true
      }
      assert_raises InvalidOptions do
        build_options(options)
      end
    end
    def test_options_validate_bad_current
      options = {
        package: true,
        current: true
      }
      assert_raises InvalidOptions do
        build_options(options)
      end
    end
    def test_options_validate_bad_in
      options = {
        package: true,
        in: true
      }
      assert_raises InvalidOptions do
        build_options(options)
      end
    end
    def test_options_validate_depricated
      options = {
        deeplink: "a:b c:d",
        deeplink_depricated: true
      }
      build_options(options)
    end
    def test_options_validate_current
      options = {
        sideload: true,
        current: true
      }
      build_options(options)
    end
    def test_options_validate_extra_sources_package
      options = {
        package: true,
        in: "",
        set_stage: true
      }
      assert_raises InvalidOptions do
        build_options(options)
      end
    end
    def test_options_exclude_command_package
      options = build_options({
        package:true,
        set_stage: true
      })
      assert options.exclude_command?
    end
    def test_options_exclude_command_build
      options = build_options({
        build:true,
        set_stage: true
      })
      assert options.exclude_command?
    end
    def test_options_exclude_command_sideload
      options = build_options({
        sideload:true,
        set_stage: true
      })
      refute options.exclude_command?
    end
    def test_options_source_command_sideload
      options = build_options({
        sideload:true,
        working: true
      })
      assert options.source_command?
    end
    def test_options_source_command_deeplink
      options = build_options({
        deeplink: true,
      })
      refute options.source_command?
    end
    def test_options_command
      options = build_options({
        deeplink: true,
      })
      assert_equal :deeplink, options.command
    end
    def test_options_device_command_true
      options = build_options({
        deeplink: true,
      })
      assert options.device_command?
    end
    def test_options_device_command_false
      options = build_options({
        build: true,
        working: true
      })
      refute options.device_command?
    end
    def test_options_has_source_false
      options = build_options({
        deeplink: true,
      })
      refute options.has_source?
    end
    def test_options_has_source_true
      options = build_options({
        deeplink: true,
        working: true
      })
      assert options.has_source?
    end
  end
end
