# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class NavigatorTest < Minitest::Test
    def setup
      Logger.set_testing
      @config = build_config_object(NavigatorTest)
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
      navigator_test(path: path, input: "Type", type: :text)
    end

    def navigator_test(path:, input:, type:, success: true)
      if success
        if type == :nav
          @requests.push(stub_request(:post, "http://111.222.333:8060#{path}").
            to_return(status: 200, body: "", headers: {}))
        elsif type == :text
          input.split(//).each do |c|
            path = "/keypress/LIT_#{CGI::escape(c)}"
            @requests.push(stub_request(:post, "http://111.222.333:8060#{path}").
              to_return(status: 200, body: "", headers: {}))
          end
        end
      end if

      navigator = Navigator.new(config: @config)
      result = nil
      if type == :nav
        result = navigator.nav(commands: [input])
      elsif type == :text
        result = navigator.type(text: input)
      end

      assert_equal success, result
    end

    def test_navigator_screen
      logger = Minitest::Mock.new
      Logger.class_variable_set(:@@instance, logger)
      navigator = Navigator.new(config: @config)

      logger.expect(:info, nil, ["Home x 5, Fwd x 3, Rev x 2,"])
      logger.expect(:unknown, nil, ["Cannot run command automatically"])
      logger.expect(:unknown, nil, ["Home x 5, Up, Rev x 2, Fwd x 2,"])

      navigator.stub(:nav, nil) do
        navigator.screen(type: :secret)
        navigator.screen(type: :reboot)
      end

      logger.verify
      Logger.set_testing
    end

    def test_navigator_screen_fail
      navigator = Navigator.new(config: @config)

      assert !navigator.screen(type: :bad)

    end

    def test_navigator_screens
      logger = Minitest::Mock.new
      Logger.class_variable_set(:@@instance, logger)
      navigator = Navigator.new(config: @config)

      navigator.instance_variable_get("@screens").each_key do |key|
        logger.expect(:unknown, nil, [key])
      end

      navigator.screens

      logger.verify
      Logger.set_testing
    end

    def test_navigator_read_char
      getc = Minitest::Mock.new
      chr = Minitest::Mock.new

      getc.expect(:call, chr)
      chr.expect(:chr, "a")


      navigator = Navigator.new(config: @config)
      STDIN.stub(:echo=, nil) do
        STDIN.stub(:raw!, nil) do
          STDIN.stub(:getc, getc) do
            assert_equal "a", navigator.read_char
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


      navigator = Navigator.new(config: @config)
      STDIN.stub(:echo=, nil) do
        STDIN.stub(:raw!, nil) do
          STDIN.stub(:getc, getc) do
            STDIN.stub(:read_nonblock, read_nonblock) do
              assert_equal "\eab", navigator.read_char
            end
          end
        end
      end
      getc.verify
      chr.verify
    end

    def test_navigator_interactive
      navigator = Navigator.new(config: @config)
      navigator.stub(:read_char, "\u0003") do
        navigator.interactive
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
        assert_equal :rev, args[:commands][0]
      }

      navigator = Navigator.new(config: @config)
      navigator.stub(:read_char, read_char) do
        navigator.stub(:nav, nav) do
          navigator.interactive
        end
      end
    end
    def test_navigator_interactive_text

      read_char = lambda {
        @i ||= 0
        char = nil
        case(@i)
        when 0
          char = "a"
        when 1
          char = "\u0003"
        end
        @i += 1
        char
      }

      type = lambda { |args|
        assert_equal "a", args[:text]
      }

      navigator = Navigator.new(config: @config)
      navigator.stub(:read_char, read_char) do
        navigator.stub(:type, type) do
          navigator.interactive
        end
      end
    end
  end
end
