# ********** Copyright Viacom, Inc. Apache 2.0 **********
require_relative "test_helper.rb"

module RokuBuilder
  class TesterTest < Minitest::Test
    def setup
      options = build_options
      @config = Config.new(options: options)
      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password",
      }
      @loader_config = {
        root_dir: "root/dir/path",
        branch: "branch",
        folders: ["source"],
        files: ["manifest"]
      }
      init_params = {tester: {root_dir: "root/dir/path"}}
      @config.instance_variable_set(:@parsed, {device_config: device_config, init_params: init_params})
      @connection = Minitest::Mock.new
      @loader = Minitest::Mock.new
      @linker = Minitest::Mock.new

    end
    def teardown
      @connection.verify
      @linker.verify
      @loader.verify
    end
    def test_tester_runtests
      tester = Tester.new(config: @config)

      @loader.expect(:sideload, nil, [@loader_config])
      @linker.expect(:launch, nil, [{options: "RunTests:true"}])
      @connection.expect(:waitfor, nil, [/\*+\s*End testing\s*\*+/])
      @connection.expect(:puts, nil, ["cont\n"])

      Loader.stub(:new, @loader) do
        Linker.stub(:new, @linker) do
          Net::Telnet.stub(:new, @connection) do
            tester.run_tests(sideload_config: @loader_config)
          end
        end
      end
    end

    def test_tester_runtests_and_handle
      waitfor = Proc.new do |end_reg, &blk|
        assert_equal(/\*+\s*End testing\s*\*+/, end_reg)
        txt = "Fake Text"
        blk.call(txt) == false
      end

      tester = Tester.new(config: @config)
      @loader.expect(:sideload, nil, [@loader_config])
      @linker.expect(:launch, nil, [{options: "RunTests:true"}])
      @connection.expect(:waitfor, nil, &waitfor)
      @connection.expect(:puts, nil, ["cont\n"])

      Loader.stub(:new, @loader) do
        Net::Telnet.stub(:new, @connection) do
          Linker.stub(:new, @linker) do
            tester.stub(:handle_text, false) do
              tester.run_tests(sideload_config: @loader_config)
            end
          end
        end
      end
    end

    def test_tester_handle_text_no_text
      tester = Tester.new(config: @config)

      text = "this\nis\na\ntest\nparagraph"
      tester.send(:handle_text, {txt: text})

      refute tester.instance_variable_get(:@in_tests)
    end

    def test_tester_handle_text_all_text
      tester = Tester.new(config: @config)
      tester.instance_variable_set(:@in_tests, true)

      text = ["this","is","a","test","paragraph"]

      tester.send(:handle_text, {txt: text.join("\n")})
      assert_equal text, tester.instance_variable_get(:@logs)
      assert tester.instance_variable_get(:@in_tests)
    end

    def test_tester_handle_text_partial_text
      tester = Tester.new(config: @config)

      text = ["this","*Start testing*","is","a","test","*End testing*","paragraph"]
      verify_text = ["***************","***************","*Start testing*","is","a","test","*End testing*","*************","*************"]

      tester.send(:handle_text, {txt: text.join("\n")})
      refute tester.instance_variable_get(:@in_tests)
      assert_equal verify_text, tester.instance_variable_get(:@logs)
    end

    def test_tester_handle_text_used_connection
      tester = Tester.new(config: @config)

      text = ["connection already in use"]

      assert_raises IOError do
        tester.send(:handle_text, {txt: text.join("\n")})
      end
    end
  end
end
