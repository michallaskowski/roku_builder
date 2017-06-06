# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "../test_helper.rb"

module RokuBuilder
  class CoreTest < Minitest::Test
    def setup
      Logger.set_testing
      RokuBuilder.setup_plugins
      register_plugins(Core)
    end
    def test_core_configure
      logger = Minitest::Mock.new
      options = {configure: true, config: File.join(test_files_path(CoreTest), "config.json")}
      config, options = build_config_options_objects(CoreTest, options, false)
      logger.expect(:unknown, nil, ["Configured"])
      Logger.class_variable_set(:@@instance, logger)
      core = Core.new(config: config)
      core.configure(options: options)
      logger.verify
    end
    def test_core_validate
      logger = Minitest::Mock.new
      config, options = build_config_options_objects(CoreTest, {validate: true}, false)
      logger.expect(:unknown, nil, ["Config Validated"])
      Logger.class_variable_set(:@@instance, logger)
      core = Core.new(config: config)
      core.validate(options: options)
      logger.verify
    end
    def test_core_increment
      config, options = build_config_options_objects(CoreTest, {increment: true, working: true}, false)
      source = File.join(test_files_path(CoreTest), "manifest_template")
      target = File.join(test_files_path(CoreTest), "manifest")
      FileUtils.cp(source, target)
      core = Core.new(config: config)
      Time.stub(:now, Time.new(2001, 02, 01)) do
        core.increment(options: options)
      end
      assert_equal "020101.2", Manifest.new(config: config).build_version
      FileUtils.rm(target)
    end
    def test_core_dostage
      stager = Minitest::Mock.new
      config, options = build_config_options_objects(CoreTest, {increment: true, working: true}, false)
      stager.expect(:stage, nil)
      core = Core.new(config: config)
      Stager.stub(:new, stager) do
        core.dostage(options: options)
      end
    end
    def test_core_dounstage
      stager = Minitest::Mock.new
      config, options = build_config_options_objects(CoreTest, {increment: true, working: true}, false)
      stager.expect(:unstage, nil)
      core = Core.new(config: config)
      Stager.stub(:new, stager) do
        core.dounstage(options: options)
      end
    end
  end
end

