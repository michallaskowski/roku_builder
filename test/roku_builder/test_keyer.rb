# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class KeyerTest < Minitest::Test
    def setup
      @config = build_config_object(KeyerTest)
      @requests = []
    end
    def teardown
      @requests.each {|req| remove_request_stub(req)}
    end
    def test_keyer_dev_id
      body = "v class=\"roku-font-5\"><label>Your Dev ID: &nbsp;</label> dev_id<hr></div>"
      @requests.push(stub_request(:get, "http://192.168.0.100/plugin_package").
        to_return(status: 200, body: body, headers: {}))

      keyer = Keyer.new(config: @config)
      dev_id = keyer.dev_id

      assert_equal "dev_id", dev_id
    end
    def test_keyer_dev_id_old_interface
      body = "<p> Your Dev ID: <font face=\"Courier\">dev_id</font> </p>"
      @requests.push(stub_request(:get, "http://192.168.0.100/plugin_package").
        to_return(status: 200, body: body, headers: {}))

      keyer = Keyer.new(config: @config)
      dev_id = keyer.dev_id

      assert_equal "dev_id", dev_id
    end

    def test_keyer_rekey_changed

      @requests.push(stub_request(:post, "http://192.168.0.100/plugin_inspect").
        to_return(status: 200, body: "", headers: {}))
      # This test fails with the following seeds due to the random number
      # generator spitting out the same number twice
      dev_id = Proc.new {"#{Random.rand(999999999999)}"}
      keyer = Keyer.new(config: @config)
      key_changed = nil
      keyer.stub(:dev_id, dev_id) do
        key_changed = keyer.rekey(keyed_pkg: File.join(test_files_path(KeyerTest), "test.pkg"),
          password: "password")
      end

      assert key_changed
    end

    def test_keyer_generate_new_key
      connection = Minitest::Mock.new()
      connection.expect(:puts, nil, ["genkey"])
      connection.expect(:waitfor, nil) do |config, &blk|
        assert_equal(/./, config['Match'])
        assert_equal(false, config['Timeout'])
        txt = "Password: password\nDevID: devid\n"
        blk.call(txt)
        true
      end
      connection.expect(:close, nil, [])

      keyer = Keyer.new(config: @config)
      Net::Telnet.stub(:new, connection) do
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
