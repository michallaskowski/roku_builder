# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "../test_helper.rb"

module RokuBuilder
  class ScripterTest < Minitest::Test
    def setup
      options = {print: "field", working: true}
      @config = build_config_object(ScripterTest, options)
    end

    def test_scripter_print_bad_attr
      assert_raises ExecutionError do
        Scripter.print(attribute: :bad, config: @config)
      end
    end

    def test_scripter_print_config_root_dir
      call_count = 0
      code = nil
      fake_print = lambda { |message, path|
        assert_equal "%s", message
        assert_equal @config.parsed[:root_dir], path
        call_count+=1
      }
      Scripter.stub(:printf, fake_print) do
        Scripter.print(attribute: :root_dir, config: @config)
      end
      assert_equal 1, call_count
    end
    def test_scripter_print_config_app_name
      call_count = 0
      code = nil
      fake_print = lambda { |message, value|
        assert_equal "%s", message
        assert_equal "<app name>", value
        call_count+=1
      }
      Scripter.stub(:printf, fake_print) do
        Scripter.print(attribute: :app_name, config: @config)
      end
      assert_equal 1, call_count
    end

    def test_scripter_print_manifest_title
      call_count = 0
      code = nil
      fake_print = lambda { |message, title|
        assert_equal "%s", message
        assert_equal "Test", title
        call_count+=1
      }
      Scripter.stub(:printf, fake_print) do
        Scripter.print(attribute: :title, config: @config)
      end
      assert_equal 1, call_count
    end

    def test_scripter_print_manifest_build_version
      call_count = 0
      code = nil
      fake_print = lambda { |message, build|
        assert_equal "%s", message
        assert_equal "010101.1", build
        call_count+=1
      }
      Scripter.stub(:printf, fake_print) do
        Scripter.print(attribute: :build_version, config: @config)
      end
      assert_equal 1, call_count
    end

    def test_scripter_print_manifest_app_version
      call_count = 0
      code = nil
      fake_print = lambda { |message, major, minor|
        assert_equal "%s.%s", message
        assert_equal "1", major
        assert_equal "0", minor
        call_count+=1
      }
      Scripter.stub(:printf, fake_print) do
        Scripter.print(attribute: :app_version, config: @config)
      end
      assert_equal 1, call_count
    end
  end
end
