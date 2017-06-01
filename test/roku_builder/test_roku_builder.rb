# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class RokuBuilderTest < Minitest::Test
    def setup
      RokuBuilder.class_variable_set(:@@plugins, [])
      @ping = Minitest::Mock.new
      @options = build_options({validate: true, device_given: false, working: true})
      @options.define_singleton_method(:device_commands){
        [:validate]
      }
      @raw = {
        devices: {
        a: {ip: "2.2.2.2"},
        b: {ip: "3.3.3.3"}
      }
      }
      @parsed = {
        device_config: {ip: "1.1.1.1"}
      }
      @config = Config.new(options: @options)
      @config.instance_variable_set(:@config, @raw)
      @config.instance_variable_set(:@parsed, @parsed)
    end
    def teardown
      @ping.verify
      RokuBuilder.class_variable_set(:@@plugins, [])
    end

    def test_roku_builder_check_devices_good
      Net::Ping::External.stub(:new, @ping) do
        @ping.expect(:ping?, true, [@parsed[:device_config][:ip], 1, 0.2, 1])
        RokuBuilder.check_devices(options: @options, config: @config)
      end
    end
    def test_roku_builder_check_devices_no_devices
      Net::Ping::External.stub(:new, @ping) do
        @ping.expect(:ping?, false, [@parsed[:device_config][:ip], 1, 0.2, 1])
        @ping.expect(:ping?, false, [@raw[:devices][:a][:ip], 1, 0.2, 1])
        @ping.expect(:ping?, false, [@raw[:devices][:b][:ip], 1, 0.2, 1])
        assert_raises DeviceError do
          RokuBuilder.check_devices(options: @options, config: @config)
        end
      end
    end
    def test_roku_builder_check_devices_changed_device
      Net::Ping::External.stub(:new, @ping) do
        @ping.expect(:ping?, false, [@parsed[:device_config][:ip], 1, 0.2, 1])
        @ping.expect(:ping?, true, [@raw[:devices][:a][:ip], 1, 0.2, 1])
        RokuBuilder.check_devices(options: @options, config: @config)
        assert_equal @raw[:devices][:a][:ip], @config.parsed[:device_config][:ip]
      end
    end
    def test_roku_builder_check_devices_bad_device
      Net::Ping::External.stub(:new, @ping) do
        @options[:device_given] = true
        @ping.expect(:ping?, false, [@parsed[:device_config][:ip], 1, 0.2, 1])
        assert_raises DeviceError do
          RokuBuilder.check_devices(options: @options, config: @config)
        end
      end
    end
    def test_roku_builder_check_devices
      Net::Ping::External.stub(:new, @ping) do
        @options = build_options({validate: true, device_given: false, working: true})
        RokuBuilder.check_devices(options: @options, config: @config)
      end
    end

    def test_roku_builder_run_debug
      tests = [
        {options: {debug: true}, method: :set_debug},
        {options: {verbose: true}, method: :set_info},
        {options: {}, method: :set_warn}
      ]
      tests.each do |test|
        logger = Minitest::Mock.new
        logger.expect(:call, nil)

        Logger.stub(test[:method], logger) do
          RokuBuilder.initialize_logger(options: test[:options])
        end

        logger.verify
      end
    end
    def test_roku_builder_options_parse_simple
      options = "a:b, c:d"
      options = RokuBuilder.options_parse(options: options)
      refute_nil options[:a]
      refute_nil options[:c]
      assert_equal "b", options[:a]
      assert_equal "d", options[:c]
    end
    def test_roku_builder_options_parse_complex
      options = "a:b:c, d:e:f"
      options = RokuBuilder.options_parse(options: options)
      refute_nil options[:a]
      refute_nil options[:d]
      assert_equal "b:c", options[:a]
      assert_equal "e:f", options[:d]
    end
    def test_roku_builder_plugins_empty
      RokuBuilder.process_plugins
      assert_equal Array, RokuBuilder.plugins.class
      assert_equal 0, RokuBuilder.plugins.count
    end
    def test_roku_builder_plugins_empty_no_setup
      assert_equal Array, RokuBuilder.plugins.class
      assert_equal 0, RokuBuilder.plugins.count
    end
    def test_roku_builder_plugins_registered
      RokuBuilder.register_plugin(TestPlugin)
      RokuBuilder.process_plugins
      assert_equal Array, RokuBuilder.plugins.class
      assert_equal 1, RokuBuilder.plugins.count
      assert_equal TestPlugin, RokuBuilder.plugins[0]
    end
    def test_roku_builder_plugins_duplicate_classes
      RokuBuilder.register_plugin(TestPlugin)
      RokuBuilder.register_plugin(TestPlugin)
      assert_raises ImplementationError do
        RokuBuilder.process_plugins
      end
    end
    def test_roku_builder_plugins_dependencies
      RokuBuilder.register_plugin(TestPlugin)
      RokuBuilder.register_plugin(TestPlugin3)
      RokuBuilder.process_plugins
    end
    def test_roku_builder_plugins_dependencies
      RokuBuilder.register_plugin(TestPlugin3)
      assert_raises ImplementationError do
        RokuBuilder.process_plugins
      end
    end
  end
  class TestPlugin
    extend Plugin
  end
  class TestPlugin2
    extend Plugin
  end
  class TestPlugin3
    extend Plugin
    def self.dependencies
      ["test"]
    end
  end
end

