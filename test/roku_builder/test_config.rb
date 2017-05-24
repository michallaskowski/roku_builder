# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class ConfigTest < Minitest::Test
    def setup
      Logger.set_testing
    end

    def test_config_init
      options = build_options({config: File.join(test_files_path(ConfigTest), "config.json"), validate: true})
      config = Config.new(options: options)
      config.load
    end

    def test_config_expand_path
      options = build_options({config: File.join(test_files_path(ConfigTest), "config.json"), validate: true})
      options[:config].sub!(/#{File.expand_path("~")}/, "~")
        config = Config.new(options: options)
      config.load
    end

    def test_missing_config
      options = build_options({config: File.join(test_files_path(ConfigTest), "missing.json"), validate: true})
      assert_raises ArgumentError do
        config = Config.new(options: options)
        config.load
      end
    end

    def test_invalid_config
      options = build_options({config: File.join(test_files_path(ConfigTest), "bad.json"), validate: true})
      assert_raises InvalidConfig do
        config = Config.new(options: options)
        config.load
        config.validate
      end
    end

    def test_non_json_config
      options = build_options({config: File.join(test_files_path(ConfigTest), "non_json.json"), validate: true})
      assert_raises InvalidConfig do
        config = Config.new(options: options)
        config.load
      end
    end

    def test_config_parse
      options = build_options({config: File.join(test_files_path(ConfigTest), "config.json"), validate: true})
      config = Config.new(options: options)
      config.load
      config.parse
      assert_equal Hash, config.parsed.class
    end

    def test_config_read
      options = build_options({config: File.join(test_files_path(ConfigTest), "config.json"), validate: true})
      config = Config.new(options: options)
      config.load
      assert_equal :roku, config.raw[:devices][:default]
      assert_equal :p1, config.raw[:projects][:default]
    end

    def test_config_read_parent
      options = build_options({config: File.join(test_files_path(ConfigTest), "child.json"), validate: true})
      config = Config.new(options: options)
      config.load
      assert_equal :roku, config.raw[:devices][:default]
      assert_equal :p1, config.raw[:projects][:default]
    end

    def test_config_read_parent
      options = build_options({config: File.join(test_files_path(ConfigTest), "parent_projects.json"), validate: true})
      config = Config.new(options: options)
      config.load
      assert_equal "app", config.raw[:projects][:p1][:app_name]
    end

    def test_config_edit
      orginal = File.join(test_files_path(ConfigTest), "config.json")
      tmp = File.join(test_files_path(ConfigTest), "tmpconfig.json")
      FileUtils.cp(orginal, tmp)
      options = build_options({config: tmp, edit_params: "ip:123.456.789", validate: true})
      config = Config.new(options: options)
      config.load
      config.edit
      options = build_options({config: tmp, validate: true})
      config = Config.new(options: options)
      config.load
      assert_equal "123.456.789", config.raw[:devices][:roku][:ip]
      FileUtils.rm(tmp)
    end

    def test_config_update_package
      options = build_options({config: File.join(test_files_path(ConfigTest), "config.json"), package: true, stage: :production, set_stage: true})
      config = Config.new(options: options)
      config.load
      config.parse
      options[:build_version] = "BUILDVERSION"
      config.update
      assert_equal "app - production - BUILDVERSION", config.parsed[:package_config][:app_name_version]
      assert_equal "/tmp/app_production_BUILDVERSION", config.parsed[:package_config][:out_file]
      assert_equal "/tmp/app_production_BUILDVERSION", config.parsed[:inspect_config][:pkg]
    end

    def test_config_update_build
      options = build_options({config: File.join(test_files_path(ConfigTest), "config.json"), build: true, stage: :production, set_stage: true})
      config = Config.new(options: options)
      config.load
      config.parse
      options[:build_version] = "BUILDVERSION"
      config.update
      assert_equal "/tmp/app_production_BUILDVERSION", config.parsed[:build_config][:out_file]
    end

    def test_config_update_sideload
      options = build_options({config: File.join(test_files_path(ConfigTest), "config.json"), sideload: true, stage: :production, set_stage: true, out: "/tmp2"})
      config = Config.new(options: options)
      config.load
      config.parse
      options[:build_version] = "BUILDVERSION"
      config.update
      assert_equal "/tmp2/app_production_BUILDVERSION", config.parsed[:sideload_config][:out_file]
    end

    def test_config_configure_creation
      target_config = File.join(test_files_path(ConfigTest), "configure_test.json")
      options = build_options({config: target_config, configure: true})
      File.delete(target_config) if File.exist?(target_config)
      refute File.exist?(target_config)
      config = Config.new(options: options)
      config.configure
      assert File.exist?(target_config)
      File.delete(target_config) if File.exist?(target_config)
    end

    def test_config_configure_edit_params
      target_config = File.join(test_files_path(ConfigTest), "configure_test.json")
      options = build_options({
        config: target_config,
        configure: true,
        edit_params: "ip:111.222.333.444"
      })
      File.delete(target_config) if File.exist?(target_config)
      refute File.exist?(target_config)
      config = Config.new(options: options)
      config.configure
      assert File.exist?(target_config)
      assert_equal "111.222.333.444", config.raw[:devices][config.raw[:devices][:default]][:ip]
      File.delete(target_config) if File.exist?(target_config)
    end

    def test_config_configure_edit_params
      target_config = File.join(test_files_path(ConfigTest), "configure_test.json")
      options = build_options({
        config: target_config,
        configure: true
      })
      File.delete(target_config) if File.exist?(target_config)
      refute File.exist?(target_config)
      config = Config.new(options: options)
      config.configure
      assert File.exist?(target_config)
      assert_raises InvalidOptions do
        config.configure
      end
      File.delete(target_config) if File.exist?(target_config)
    end
  end
end
