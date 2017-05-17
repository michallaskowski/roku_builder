# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class MonitorTest < Minitest::Test
    def setup
      options = build_options
      @config = Config.new(options: options)
      @connection = Minitest::Mock.new
      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password"
      }
      @config.instance_variable_set(:@parsed, {device_config: device_config, init_params: {}})
      @monitor = Monitor.new(config: @config)
    end
    def teardown
      @connection.verify
    end
    def test_monitor_monit
      @connection.expect(:waitfor, nil) do |config|
        assert_equal(/./, config['Match'])
        assert_equal(false, config['Timeout'])
      end

      readline = proc {
        sleep(0.1)
        "q"
      }

      Readline.stub(:readline, readline) do
        Net::Telnet.stub(:new, @connection) do
          @monitor.monitor(type: :main)
        end
      end

    end

    def test_monitor_monit_and_manage
      @monitor.instance_variable_set(:@show_prompt, true)

      @connection.expect(:waitfor, nil) do |config, &blk|
        assert_equal(/./, config['Match'])
        assert_equal(false, config['Timeout'])
        txt = "Fake Text"
        blk.call(txt) == ""
      end

      readline = proc {
        sleep(0.1)
        "q"
      }

      Readline.stub(:readline, readline) do
        Net::Telnet.stub(:new, @connection) do
          @monitor.stub(:manage_text, "") do
            @monitor.monitor(type: :main)
          end
        end
      end
    end

    def test_monitor_monit_input
      @monitor.instance_variable_set(:@show_prompt, true)

      @connection.expect(:waitfor, nil) do |config|
        assert_equal(/./, config['Match'])
        assert_equal(false, config['Timeout'])
      end
      @connection.expect(:puts, nil) do |text|
        assert_equal("text", text)
        @monitor.instance_variable_set(:@show_prompt, true)
      end

      readline = proc {
        @count ||= 0
        sleep(0.1)
        case @count
        when 0
          @count += 1
          "text"
        else
          "q"
        end
      }

      Readline.stub(:readline, readline) do
        Net::Telnet.stub(:new, @connection) do
          @monitor.monitor(type: :main)
        end
      end
    end

    def test_monitor_manage_text
      mock = Minitest::Mock.new
      @monitor.instance_variable_set(:@show_prompt, true)
      @monitor.instance_variable_set(:@mock, mock)

      def @monitor.puts(input)
        @mock.puts(input)
      end

      mock.expect(:puts, nil, ["midline split\n"])

      all_text = "midline "
      txt = "split\nBrightScript Debugger> "

      result = @monitor.send(:manage_text, {all_text: all_text, txt: txt})

      assert_equal "", result

      mock.verify

    end
  end
end
