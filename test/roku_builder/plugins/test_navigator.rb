# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "../test_helper.rb"

module RokuBuilder
  class NavigatorTest < Minitest::Test
    def setup
      Logger.set_testing
      RokuBuilder.setup_plugins
      unless RokuBuilder.plugins.include?(Navigator)
        RokuBuilder.register_plugin(Navigator)
      end
      @requests = []
    end
    def teardown
      @requests.each {|req| remove_request_stub(req)}
    end
    def test_navigator_nav
      commands = {
        up: "Up",
        down: "Down",
        right: "Right",
        left: "Left",
        select: "Select",
        back: "Back",
        home: "Home",
        rew: "Rev",
        ff: "Fwd",
        play: "Play",
        replay: "InstantReplay"
      }
      commands.each {|k,v|
        path = "/keypress/#{v}"
        navigator_test(path: path, input: k, type: :nav)
      }
    end

    def test_navigator_nav_fail
      path = ""
      navigator_test(path: path, input: :bad, type: :nav, success: false)
    end

    def test_navigator_type
      path = "keypress/LIT_"
      navigator_test(path: path, input: "Type", type: :type)
    end

    def navigator_test(path:, input:, type:, success: true)
      if success
        if type == :nav
          @requests.push(stub_request(:post, "http://192.168.0.100:8060#{path}").
            to_return(status: 200, body: "", headers: {}))
        elsif type == :type
          input.split(//).each do |c|
            path = "/keypress/LIT_#{CGI::escape(c)}"
            @requests.push(stub_request(:post, "http://192.168.0.100:8060#{path}").
              to_return(status: 200, body: "", headers: {}))
          end
        end
      end
      options = {}
      options[type] = input.to_s
      config, options = build_config_options_objects(NavigatorTest, options, false)
      navigator = Navigator.new(config: config)
      if success
        navigator.send(type, options: options)
      else
        assert_raises ExecutionError do
          navigator.send(type, options: options)
        end
      end
    end

    def test_navigator_screen_secret
      logger = Minitest::Mock.new
      Logger.class_variable_set(:@@instance, logger)
      options = {screen: "secret"}
      config, options = build_config_options_objects(NavigatorTest, options, false)
      navigator = Navigator.new(config: config)

      stub_request(:post, "http://192.168.0.100:8060/keypress/Home").
        to_return(status: 200, body: "", headers: {})
      stub_request(:post, "http://192.168.0.100:8060/keypress/Fwd").
        to_return(status: 200, body: "", headers: {})
      stub_request(:post, "http://192.168.0.100:8060/keypress/Rev").
        to_return(status: 200, body: "", headers: {})

      logger.expect(:info, nil, ["Home x 5, Fwd x 3, Rev x 2,"])
      5.times do
        logger.expect(:debug, nil, ["Send Command: /keypress/Home"])
      end
      3.times do
        logger.expect(:debug, nil, ["Send Command: /keypress/Fwd"])
      end
      2.times do
        logger.expect(:debug, nil, ["Send Command: /keypress/Rev"])
      end

      navigator.screen(options: options)

      logger.verify
      Logger.set_testing
    end
    def test_navigator_screen_reboot
      logger = Minitest::Mock.new
      Logger.class_variable_set(:@@instance, logger)
      options = {screen: "reboot"}
      config, options = build_config_options_objects(NavigatorTest, options, false)
      navigator = Navigator.new(config: config)

      logger.expect(:unknown, nil, ["Cannot run command automatically"])
      logger.expect(:unknown, nil, ["Home x 5, Up, Rev x 2, Fwd x 2,"])

      navigator.screen(options: options)

      logger.verify
      Logger.set_testing
    end

    def test_navigator_screen_fail
      options = {screen: "bad"}
      config, options = build_config_options_objects(NavigatorTest, options, false)
      navigator = Navigator.new(config: config)
      assert_raises ExecutionError do
        navigator.screen(options: options)
      end
    end

    def test_navigator_screens
      logger = Minitest::Mock.new
      Logger.class_variable_set(:@@instance, logger)
      options = {screens: true}
      config, options = build_config_options_objects(NavigatorTest, options, false)
      navigator = Navigator.new(config: config)

      navigator.instance_variable_get("@screens").each_key do |key|
        logger.expect(:unknown, nil, [key])
      end

      navigator.screens(options: options)

      logger.verify
      Logger.set_testing
    end

    def test_navigator_read_char
      getc = Minitest::Mock.new
      chr = Minitest::Mock.new

      getc.expect(:call, chr)
      chr.expect(:chr, "a")

      options = {navigate: true}
      config, options = build_config_options_objects(NavigatorTest, options, false)

      navigator = Navigator.new(config: config)
      STDIN.stub(:echo=, nil) do
        STDIN.stub(:raw!, nil) do
          STDIN.stub(:getc, getc) do
            assert_equal "a", navigator.send(:read_char)
          end
        end
      end
      getc.verify
      chr.verify
    end

    def test_navigator_read_char_multichar
      getc = Minitest::Mock.new
      chr = Minitest::Mock.new
      read_nonblock = Minitest::Mock.new

      getc.expect(:call, chr)
      chr.expect(:chr, "\e")
      read_nonblock.expect(:call, "a", [3])
      read_nonblock.expect(:call, "b", [2])

      options = {navigate: true}
      config, options = build_config_options_objects(NavigatorTest, options, false)

      navigator = Navigator.new(config: config)
      STDIN.stub(:echo=, nil) do
        STDIN.stub(:raw!, nil) do
          STDIN.stub(:getc, getc) do
            STDIN.stub(:read_nonblock, read_nonblock) do
              assert_equal "\eab", navigator.send(:read_char)
            end
          end
        end
      end
      getc.verify
      chr.verify
    end

    def test_navigator_interactive
      options = {navigate: true}
      config, options = build_config_options_objects(NavigatorTest, options, false)
      navigator = Navigator.new(config: config)
      navigator.stub(:read_char, "\u0003") do
        navigator.navigate(options: options)
      end
    end

    def test_navigator_interactive_nav
      read_char = lambda {
        @i ||= 0
        char = nil
        case(@i)
        when 0
          char = "<"
        when 1
          char = "\u0003"
        end
        @i += 1
        char
      }
      nav = lambda { |args|
        assert_equal :rew, args[:commands][0]
      }
      options = {navigate: true}
      config, options = build_config_options_objects(NavigatorTest, options, false)
      navigator = Navigator.new(config: config)
      navigator.stub(:read_char, read_char) do
        navigator.stub(:nav, nav) do
          navigator.navigate(options: options)
        end
      end
    end
    def test_navigator_hendle_interactive_text
      stub_request(:post, "http://192.168.0.100:8060/keypress/LIT_a").
        to_return(status: 200, body: "", headers: {})
      options = {navigate: true}
      config, options = build_config_options_objects(NavigatorTest, options, false)
      navigator = Navigator.new(config: config)
      navigator.send(:handle_navigate_input, "a")
    end
    def test_navigator_hendle_interactive_command
      stub_request(:post, "http://192.168.0.100:8060/keypress/Play").
        to_return(status: 200, body: "", headers: {})
      options = {navigate: true}
      config, options = build_config_options_objects(NavigatorTest, options, false)
      navigator = Navigator.new(config: config)
      navigator.send(:handle_navigate_input, "=")
    end
  end
end
