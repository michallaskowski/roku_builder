# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"
module RokuBuilder
  class ControllerCommandsTest < Minitest::Test

    def test_controller_commands_validate
      logger = Minitest::Mock.new
      Logger.class_variable_set(:@@instance, logger)
      logger.expect(:info, nil, ["Config validated"])
      code = ControllerCommands.validate()
      assert_equal SUCCESS, code
      logger.verify
      Logger.set_testing
    end
    def test_controller_commands_sideload
      loader = Minitest::Mock.new
      stager = Minitest::Mock.new

      options = build_options({sideload: true, config: "~/.roku_config.rb", working: true})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config)
      config.parse
      # Test Success
      loader.expect(:sideload, [SUCCESS, "build_version"], [config.parsed[:sideload_config]])
      stager.expect(:stage, true)
      stager.expect(:unstage, true)
      stager.expect(:method, :git)

      code = nil
      Loader.stub(:new, loader) do
        Stager.stub(:new, stager) do
          code = Controller.send(:execute_commands, {options: options, config: config})
        end
      end
      assert_equal SUCCESS, code

      stager.expect(:stage, true)
      stager.expect(:unstage, true)

      # Test Failure
      loader.expect(:sideload, [FAILED_SIDELOAD, "build_version"], [config.parsed[:sideload_config]])
      Loader.stub(:new, loader) do
        Stager.stub(:new, stager) do
          code = Controller.send(:execute_commands, {options: options, config: config})
        end
      end
      assert_equal FAILED_SIDELOAD, code

      loader.verify
      stager.verify
    end

    def test_controller_commands_package
      keyer = Minitest::Mock.new
      loader = Minitest::Mock.new
      stager = Minitest::Mock.new
      packager = Minitest::Mock.new
      inspector = Minitest::Mock.new

      options = build_options({package: true, inspect: true, out_folder: "/tmp", config: "~/.roku_config.json", set_stage: true})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config)
      config.parse
      info = {app_name: "app", dev_id: "id", creation_date: "date", dev_zip: ""}

      loader.expect(:sideload, [SUCCESS, "build_version"], [config.parsed[:sideload_config]])
      keyer.expect(:rekey, true, [config.parsed[:key]])
      packager.expect(:package, true, [config.parsed[:package_config]])
      inspector.expect(:inspect, info, [config.parsed[:inspect_config]])
      stager.expect(:stage, true)
      stager.expect(:unstage, true)
      stager.expect(:method, :git)

      code = nil
      Keyer.stub(:new, keyer) do
        Loader.stub(:new, loader) do
          Packager.stub(:new, packager) do
            Inspector.stub(:new, inspector) do
              Stager.stub(:new, stager) do
                ::Logger.stub(:new, ::Logger.new("/dev/null")) do
                  code = Controller.send(:execute_commands, {options: options, config: config})
                end
              end
            end
          end
        end
      end
      assert_equal SUCCESS, code

      keyer.verify
      loader.verify
      stager.verify
      packager.verify
      inspector.verify
    end

    def test_controller_commands_package_outfile
      keyer = Minitest::Mock.new
      loader = Minitest::Mock.new
      stager = Minitest::Mock.new
      packager = Minitest::Mock.new
      inspector = Minitest::Mock.new

      options = build_options({package: true, inspect: true, out: "/tmp/out.pkg", config: "~/.roku_config.json", set_stage: true})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config(ControllerCommandsTest))
      config.parse
      FileUtils.cp(File.join(config.parsed[:root_dir], "manifest_template"), File.join(config.parsed[:root_dir], "manifest"))
      info = {app_name: "app", dev_id: "id", creation_date: "date", dev_zip: ""}

      loader.expect(:sideload, [SUCCESS, "build_version"], [config.parsed[:sideload_config]])
      keyer.expect(:rekey, true, [config.parsed[:key]])
      packager.expect(:package, true, [config.parsed[:package_config]])
      inspector.expect(:inspect, info, [config.parsed[:inspect_config]])
      stager.expect(:stage, true)
      stager.expect(:unstage, true)
      stager.expect(:method, :git)

      code = nil
      Keyer.stub(:new, keyer) do
        Loader.stub(:new, loader) do
          Packager.stub(:new, packager) do
            Inspector.stub(:new, inspector) do
              Stager.stub(:new, stager) do
                ::Logger.stub(:new, ::Logger.new("/dev/null")) do
                  code = Controller.send(:execute_commands, {options: options, config: config})
                end
              end
            end
          end
        end
      end
      assert_equal SUCCESS, code

      keyer.verify
      loader.verify
      stager.verify
      packager.verify
      inspector.verify
      FileUtils.rm(File.join(config.parsed[:root_dir], "manifest"))
    end

    def test_controller_commands_build
      loader = Minitest::Mock.new
      stager = Minitest::Mock.new

      code = nil
      options = build_options({build: true, out_folder: "/tmp", config: "~/.roku_config.json", working: true})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config(ControllerCommandsTest))
      config.parse
      FileUtils.cp(File.join(config.parsed[:root_dir], "manifest_template"), File.join(config.parsed[:root_dir], "manifest"))
      loader.expect(:build, "/tmp/build", [config.parsed[:build_config]])
      stager.expect(:stage, true)
      stager.expect(:unstage, true)
      stager.expect(:method, :git)

      Loader.stub(:new, loader) do
        Stager.stub(:new, stager) do
          code = Controller.send(:execute_commands, {options: options, config: config})
        end
      end
      assert_equal SUCCESS, code
      loader.verify
      stager.verify
      FileUtils.rm(File.join(config.parsed[:root_dir], "manifest"))
    end
    def test_controller_commands_update
      stager = Minitest::Mock.new

      code = nil
      options = build_options({update: true, out_folder: "/tmp", config: "~/.roku_config.json", working: true})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config(ControllerCommandsTest))
      config.parse
      FileUtils.cp(File.join(config.parsed[:root_dir], "manifest_template"), File.join(config.parsed[:root_dir], "manifest"))
      stager.expect(:stage, true)
      stager.expect(:unstage, true)
      Stager.stub(:new, stager) do
        code = Controller.send(:execute_commands, {options: options, config: config})
      end
      stager.verify
      assert_equal SUCCESS, code
      FileUtils.rm(File.join(config.parsed[:root_dir], "manifest"))
    end

    def test_controller_commands_deeplink
      mock = Minitest::Mock.new

      code = nil
      options = build_options({deeplink: true, deeplink_options: "a:b", config: "~/.roku_config.json"})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config)
      config.parse
      mock.expect(:launch, "true", [config.parsed[:deeplink_config]])
      Linker.stub(:new, mock) do
        code = Controller.send(:execute_commands, {options: options, config: config})
      end
      mock.verify
      assert_equal SUCCESS, code
    end
    def test_controller_commands_deeplink_sideload
      mock = Minitest::Mock.new

      ran_sideload = false

      sideload =  Proc.new {|a, b, c| ran_sideload = true}

      code = nil
      options = build_options({deeplink: true, set_stage: true, deeplink_options: "a:b", config: "~/.roku_config.json"})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config)
      config.parse
      mock.expect(:launch, "true", [config.parsed[:deeplink_config]])
      Linker.stub(:new, mock) do
        ControllerCommands.stub(:sideload, sideload) do
          code = Controller.send(:execute_commands, {options: options, config: config})
        end
      end
      mock.verify
      assert_equal SUCCESS, code
      assert ran_sideload
    end
    def test_controller_commands_deeplink_fail
      mock = Minitest::Mock.new
      stager = Minitest::Mock.new

      code = nil
      options = build_options({deeplink: true, deeplink_options: "a:b", config: "~/.roku_config.json"})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config)
      config.parse
      mock.expect(:launch, false, [config.parsed[:deeplink_config]])
      stager.expect(:stage, true)
      stager.expect(:unstage, true)
      Linker.stub(:new, mock) do
        Stager.stub(:new, stager) do
          code = Controller.send(:execute_commands, {options: options, config: config})
        end
      end
      mock.verify
      assert_equal FAILED_DEEPLINKING, code
    end
    def test_controller_commands_delete
      loader = Minitest::Mock.new

      options = build_options({delete: true, config: "~/.roku_config.json"})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config)
      config.parse
      loader.expect(:unload, nil)
      code = nil
      Loader.stub(:new, loader) do
        code = Controller.send(:execute_commands, {options: options, config: config})
      end
      assert_equal SUCCESS, code
      loader.verify
    end
    def test_controller_commands_monitor
      monitor = Minitest::Mock.new

      options = build_options({monitor: "main", config: "~/.roku_config.json"})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config)
      config.parse
      monitor.expect(:monitor, nil, [config.parsed[:monitor_config]])
      code = nil
      Monitor.stub(:new, monitor) do
        code = Controller.send(:execute_commands, {options: options, config: config})
      end
      assert_equal SUCCESS, code
      monitor.verify
    end
    def test_controller_commands_navigate
      navigator = Minitest::Mock.new

      options = build_options({navigate: "up", config: "~/.roku_config.json"})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config)
      config.parse
      navigator.expect(:nav, true, [config.parsed[:navigate_config]])
      code = nil
      Navigator.stub(:new, navigator) do
        code = Controller.send(:execute_commands, {options: options, config: config})
      end
      assert_equal SUCCESS, code
      navigator.verify
    end
    def test_controller_commands_navigate_fail
      navigator = Minitest::Mock.new

      options = build_options({navigate: "up", config: ":execute_commands,/.roku_config.json"})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config)
      config.parse
      navigator.expect(:nav, nil, [config.parsed[:navigate_config]])
      code = nil
      Navigator.stub(:new, navigator) do
        code = Controller.send(:execute_commands, {options: options, config: config})
      end
      assert_equal FAILED_NAVIGATING, code
      navigator.verify
    end
    def test_controller_commands_screen
      navigator = Minitest::Mock.new

      options = build_options({screen: "secret", config: "~/.roku_config.json"})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config)
      config.parse
      navigator.expect(:screen, true, [config.parsed[:screen_config]])
      code = nil
      Navigator.stub(:new, navigator) do
        code = Controller.send(:execute_commands, {options: options, config: config})
      end
      assert_equal SUCCESS, code
      navigator.verify
    end
    def test_controller_commands_screens
      navigator = Minitest::Mock.new

      options = build_options({screens: true, config: "~/.roku_config.json"})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config)
      config.parse
      navigator.expect(:screens, true)
      code = nil
      Navigator.stub(:new, navigator) do
        code = Controller.send(:execute_commands, {options: options, config: config})
      end
      assert_equal SUCCESS, code
      navigator.verify
    end
    def test_controller_commands_text
      navigator = Minitest::Mock.new

      options = build_options({text: "text string", config: "~/.roku_config.json"})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config)
      config.parse
      navigator.expect(:type, true, [config.parsed[:text_config]])
      code = nil
      Navigator.stub(:new, navigator) do
        code = Controller.send(:execute_commands, {options: options, config: config})
      end
      assert_equal SUCCESS, code
      navigator.verify
    end
    def test_controller_commands_test
      tester = Minitest::Mock.new
      stager = Minitest::Mock.new

      options = build_options({test: true, config: "~/.roku_config.json", working: true})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config)
      config.parse
      tester.expect(:run_tests, true, [config.parsed[:test_config]])
      stager.expect(:stage, true)
      stager.expect(:unstage, true)
      code = nil

      Stager.stub(:new, stager) do
        Tester.stub(:new, tester) do
          code = Controller.send(:execute_commands, {options: options, config: config})
        end
      end
      assert_equal SUCCESS, code
      tester.verify
      stager.verify
    end
    def test_controller_commands_screencapture
      inspector = Minitest::Mock.new

      options = build_options({screencapture: true, out: "/tmp/capture.jpg", config: "~/.roku_config.json"})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config)
      config.parse
      inspector.expect(:screencapture, true, [config.parsed[:screencapture_config]])
      code = nil
      Inspector.stub(:new, inspector) do
        code = Controller.send(:execute_commands, {options: options, config: config})
      end
      assert_equal SUCCESS, code
      inspector.verify
    end
    def test_controller_commands_screencapture_fail
      inspector = Minitest::Mock.new

      options = build_options({screencapture: true, out: "/tmp", config: "~/.roku_config.json"})
      config = Config.new(options: options)
      config.instance_variable_set(:@config, good_config)
      config.parse
      inspector.expect(:screencapture, false, [config.parsed[:screencapture_config]])
      code = nil
      Inspector.stub(:new, inspector) do
        code = Controller.send(:execute_commands, {options: options, config: config })
      end
      assert_equal FAILED_SCREENCAPTURE, code
      inspector.verify
    end
    def test_controller_commands_print
      stager = Minitest::Mock.new

      options = build_options({print: 'title', config: "~/.roku_config.json", working: true})
      configs = {stage_config: {}}
      config = Config.new(options: options)
      config.instance_variable_set(:@parsed, configs)
      code = nil
      scripter_config = {attribute: :title, configs: configs}
      print_check = lambda {|print_config| SUCCESS if print_config == scripter_config }
      stager.expect(:stage, true)
      stager.expect(:unstage, true)

      Stager.stub(:new, stager) do
        Scripter.stub(:print, print_check) do
          code = Controller.send(:execute_commands, {options: options, config: config})
        end
      end
      assert_equal SUCCESS, code
      stager.verify
    end
    def test_controller_commands_dostage
      stager = Minitest::Mock.new

      options = build_options({dostage: true, config: "~/.roku_config.json"})
      config = Config.new(options: options)
      config.instance_variable_set(:@parsed, {stage_config: {}})
      code = nil
      stager.expect(:stage, true)

      Stager.stub(:new, stager) do
        code = Controller.send(:execute_commands, {options: options, config: config})
      end
      assert_equal true, code
      stager.verify
    end

    def test_controller_commands_dounstage
      stager = Minitest::Mock.new

      options = build_options({dounstage: true, config: "~/.roku_config.json"})
      configs = {stage_config: {}}
      config = Config.new(options: options)
      config.instance_variable_set(:@parsed, configs)
      code = nil
      stager.expect(:unstage, true)

      Stager.stub(:new, stager) do
        code = Controller.send(:execute_commands, {options: options, config: config})
      end
      assert_equal true, code
      stager.verify
    end
  end
end
