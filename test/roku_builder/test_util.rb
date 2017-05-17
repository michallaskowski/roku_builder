# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class UtilTest < Minitest::Test
    def setup
      options = build_options
      @config = Config.new(options: options)
      @device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password"
      }
      @config.instance_variable_set(:@parsed, {device_config: @device_config, init_params: {}})
    end
    def test_util_init
      test = TestClass.new(config: @config)
      assert test.inited
    end
    def test_util_init_with_params
      init_params = {
        test_class2: { test: "test" }
      }
      @config.instance_variable_set(:@parsed, {device_config: @device_config, init_params: init_params})
      test = TestClass2.new(config: @config)
      assert test.inited
    end
    def test_util_no_init
      test = TestClass3.new(config: @config)
    end
    def test_util_options_parse_simple
      options = "a:b, c:d"
      options = Util.options_parse(options: options)
      refute_nil options[:a]
      refute_nil options[:c]
      assert_equal "b", options[:a]
      assert_equal "d", options[:c]
    end
    def test_util_options_parse_complex
      options = "a:b:c, d:e:f"
      options = Util.options_parse(options: options)
      refute_nil options[:a]
      refute_nil options[:d]
      assert_equal "b:c", options[:a]
      assert_equal "e:f", options[:d]
    end
  end

  class TestClass < Util
    def init
      @inited = true
    end
    def inited
      @inited || false
    end
  end
  class TestClass2 < Util
    def init(test:)
      @inited = (test == "test")
    end
    def inited
      @inited || false
    end
  end
  class TestClass3 < Util
  end
end
