# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"
module RokuBuilder
  class ControllerTest < Minitest::Test
    def test_controller_check_devices
      ping = Minitest::Mock.new
      options = build_options({sideload: true, device_given: false, working: true})
      raw = {
        devices: {
        a: {ip: "2.2.2.2"},
        b: {ip: "3.3.3.3"}
      }
      }
      parsed = {
        device_config: {ip: "1.1.1.1"}
      }
      config = Config.new(options: options)
      config.instance_variable_set(:@config, raw)
      config.instance_variable_set(:@parsed, parsed)

      Net::Ping::External.stub(:new, ping) do

        ping.expect(:ping?, true, [parsed[:device_config][:ip], 1, 0.2, 1])
        code = Controller.send(:check_devices, {options: options, config: config})
        assert_equal GOOD_DEVICE, code

        ping.expect(:ping?, false, [parsed[:device_config][:ip], 1, 0.2, 1])
        ping.expect(:ping?, false, [raw[:devices][:a][:ip], 1, 0.2, 1])
        ping.expect(:ping?, false, [raw[:devices][:b][:ip], 1, 0.2, 1])
        code = Controller.send(:check_devices, {options: options, config: config})
        assert_equal NO_DEVICES, code

        ping.expect(:ping?, false, [parsed[:device_config][:ip], 1, 0.2, 1])
        ping.expect(:ping?, true, [raw[:devices][:a][:ip], 1, 0.2, 1])
        code = Controller.send(:check_devices, {options: options, config: config})
        assert_equal CHANGED_DEVICE, code
        assert_equal raw[:devices][:a][:ip], config.parsed[:device_config][:ip]

        options[:device_given] = true
        ping.expect(:ping?, false, [parsed[:device_config][:ip], 1, 0.2, 1])
        code = Controller.send(:check_devices, {options: options, config: config})
        assert_equal BAD_DEVICE, code

        options = build_options({build: true, device_given: false, working: true})
        code = Controller.send(:check_devices, {options: options, config: config})
        assert_equal GOOD_DEVICE, code
      end
    end

    def test_controller_run_debug
      tests = [
        {options: {debug: true}, method: :set_debug},
        {options: {verbose: true}, method: :set_info},
        {options: {}, method: :set_warn}
      ]
      tests.each do |test|
        logger = Minitest::Mock.new
        logger.expect(:call, nil)

        Logger.stub(test[:method], logger) do
          Controller.initialize_logger(options: test[:options])
        end

        logger.verify
      end
    end
  end
end

