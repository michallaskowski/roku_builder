# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class KeyerTest < Minitest::Test
    def setup
      options = build_options
      @config = Config.new(options: options)
      @device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password"
      }
      @config.instance_variable_set(:@parsed, {root_dir: "/tmp", device_config: @device_config, init_params: {}})
      @connection = Minitest::Mock.new
      @faraday = Minitest::Mock.new
      @response = Minitest::Mock.new

    end
    def teardown
      @connection.verify
      @faraday.verify
      @response.verify
    end
    def test_keyer_dev_id
      path = "/plugin_package"
      body = "v class=\"roku-font-5\"><label>Your Dev ID: &nbsp;</label> dev_id<hr></div>"

      @connection.expect(:get, @response, [path])
      @response.expect(:body, body)
      @response.expect(:body, body)
      @faraday.expect(:request, nil, [:digest, @device_config[:user], @device_config[:password]])
      @faraday.expect(:adapter, nil, [Faraday.default_adapter])

      dev_id = nil
      keyer = Keyer.new(config: @config)
      Faraday.stub(:new, @connection, @faraday) do
        dev_id = keyer.dev_id
      end

      assert_equal "dev_id", dev_id
    end
    def test_keyer_dev_id_old_interface
      path = "/plugin_package"
      body = "<p> Your Dev ID: <font face=\"Courier\">dev_id</font> </p>"

      @connection.expect(:get, @response, [path])
      @response.expect(:body, body)
      @faraday.expect(:request, nil, [:digest, @device_config[:user], @device_config[:password]])
      @faraday.expect(:adapter, nil, [Faraday.default_adapter])


      dev_id = nil
      keyer = Keyer.new(config: @config)
      Faraday.stub(:new, @connection, @faraday) do
        dev_id = keyer.dev_id
      end

      assert_equal "dev_id", dev_id
    end

    def test_keyer_rekey_changed
      io = Minitest::Mock.new
      path = "/plugin_inspect"
      password = "password"
      payload ={
        mysubmit: "Rekey",
        password: password,
        archive: io
      }

      @connection.expect(:post, @response) do |arg1, arg2|
        assert_equal path, arg1
        assert_equal payload[:mysubmit], arg2[:mysubmit]
        assert_equal payload[:password], arg2[:passwd]
        assert payload[:archive] === arg2[:archive]
      end
      @faraday.expect(:headers, {})
      @faraday.expect(:request, nil, [:digest, @device_config[:user], @device_config[:password]])
      @faraday.expect(:request, nil, [:multipart])
      @faraday.expect(:request, nil, [:url_encoded])
      @faraday.expect(:adapter, nil, [Faraday.default_adapter])

      # This test fails with the following seeds due to the random number
      # generator spitting out the same number twice
      # SEED=21894
      # SEED=31813
      dev_id = Proc.new {"#{Random.rand(100)}"}
      keyer = Keyer.new(config: @config)
      key_changed = nil
      Faraday.stub(:new, @connection, @faraday) do
        Faraday::UploadIO.stub(:new, io) do
          keyer.stub(:dev_id, dev_id) do
            key_changed = keyer.rekey(keyed_pkg: "pkg/path", password: password)
          end
        end
      end

      assert key_changed

      io.verify
    end

    def test_keyer_generate_new_key
      @connection.expect(:puts, nil, ["genkey"])
      @connection.expect(:waitfor, nil) do |config, &blk|
        assert_equal(/./, config['Match'])
        assert_equal(false, config['Timeout'])
        txt = "Password: password\nDevID: devid\n"
        blk.call(txt)
        true
      end
      @connection.expect(:close, nil, [])

      keyer = Keyer.new(config: @config)
      Net::Telnet.stub(:new, @connection) do
        keyer.send(:generate_new_key)
      end
    end

    def test_keyer_genkey
      loader = Minitest::Mock.new
      packager = Minitest::Mock.new

      loader.expect(:sideload, nil)
      packager.expect(:package, nil, [app_name_version: "key_dev_id", out_file: "/tmp/key_dev_id.pkg", password: "password"])

      keyer = Keyer.new(config: @config)
      Loader.stub(:new, loader) do
        Packager.stub(:new, packager) do
          keyer.stub(:generate_new_key, ["password", "dev_id"]) do
            keyer.genkey
          end
        end
      end

      loader.verify
      packager.verify
    end
  end
end
