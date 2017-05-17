# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class LoaderTest < Minitest::Test
    def test_loader_sideload
      connection = Minitest::Mock.new
      faraday = Minitest::Mock.new
      io = Minitest::Mock.new
      response = Minitest::Mock.new
      navigator = Minitest::Mock.new

      options = build_options
      config = Config.new(options: options)
      root_dir = File.join(File.dirname(__FILE__), "test_files", "loader_test")
      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password",
        init_params: {root_dir: root_dir}
      }
      config.instance_variable_set(:@parsed, {device_config: device_config, init_params: {}})
      loader_config = {
        content: {
          folders: ["source"],
          files: ["manifest"]
        }
      }
      payload = {
        mysubmit: "Replace",
        archive: io,
      }
      path = "/plugin_install"

      navigator.expect(:nav, nil, [commands: [:home]])
      stub_request(:post, "#{device_config[:ip]}").with(body: payload)

      loader = Loader.new(config: config)
      result = nil
      build_version = nil
      loader.stub(:build, "zip_file") do
        File.stub(:delete, nil) do
          Navigator.stub(:new, navigator) do
            result, build_version = loader.sideload(**loader_config)
          end
        end
      end

      assert_equal "build_version", build_version
      assert_equal SUCCESS, result

      connection.verify
      faraday.verify
      io.verify
      response.verify
    end
    def test_loader_sideload_infile
      connection = Minitest::Mock.new
      faraday = Minitest::Mock.new
      io = Minitest::Mock.new
      response = Minitest::Mock.new
      navigator = Minitest::Mock.new

      infile = File.join(File.dirname(__FILE__), "test_files", "loader_test", "infile_test.zip")
      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password"
      }
      loader_config = {
        infile: infile
      }
      payload = {
        mysubmit: "Replace",
        archive: io,
      }
      path = "/plugin_install"

      navigator.expect(:nav, nil, [commands: [:home]])
      faraday.expect(:headers, {})
      faraday.expect(:request, nil, [:digest, device_config[:user], device_config[:password]])
      faraday.expect(:request, nil, [:multipart])
      faraday.expect(:request, nil, [:url_encoded])
      faraday.expect(:adapter, nil, [Faraday.default_adapter])
      connection.expect(:post, response) do |arg1, arg2|
        assert_equal path, arg1
        assert_equal payload[:mysubmit], arg2[:mysubmit]
        assert payload[:archive] === arg2[:archive]
      end
      response.expect(:status, 200)
      response.expect(:body, "Install Success")
      response.expect(:status, 200)
      response.expect(:body, "Install Success")

      loader = Loader.new(**device_config)
      result = nil
      build_version = nil
      ManifestManager.stub(:build_version, "build_version") do
        Faraday.stub(:new, connection, faraday) do
          Faraday::UploadIO.stub(:new, io) do
            File.stub(:delete, nil) do
              Navigator.stub(:new, navigator) do
                result, build_version = loader.sideload(**loader_config)
              end
            end
          end
        end
      end

      assert_equal "build_version", build_version
      assert_equal SUCCESS, result

      connection.verify
      faraday.verify
      io.verify
      response.verify
    end
    def test_loader_sideload_update
      connection = Minitest::Mock.new
      faraday = Minitest::Mock.new
      io = Minitest::Mock.new
      response = Minitest::Mock.new
      navigator = Minitest::Mock.new

      root_dir = File.join(File.dirname(__FILE__), "test_files", "loader_test")
      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password",
        init_params: {root_dir: root_dir}
      }
      loader_config = {
        update_manifest: true,
        content: {
        folders: ["source"],
        files: ["manifest"]
      }
      }
      payload = {
        mysubmit: "Replace",
        archive: io,
      }
      path = "/plugin_install"

      navigator.expect(:nav, nil, [commands: [:home]])
      faraday.expect(:headers, {})
      faraday.expect(:request, nil, [:digest, device_config[:user], device_config[:password]])
      faraday.expect(:request, nil, [:multipart])
      faraday.expect(:request, nil, [:url_encoded])
      faraday.expect(:adapter, nil, [Faraday.default_adapter])
      connection.expect(:post, response) do |arg1, arg2|
        assert_equal path, arg1
        assert_equal payload[:mysubmit], arg2[:mysubmit]
        assert payload[:archive] === arg2[:archive]
      end
      response.expect(:status, 200)
      response.expect(:body, "Install Success")
      response.expect(:status, 200)
      response.expect(:body, "Install Success")

      loader = Loader.new(**device_config)
      result = nil
      build_version = nil
      ManifestManager.stub(:update_build, "build_version") do
        loader.stub(:build, "zip_file") do
          Faraday.stub(:new, connection, faraday) do
            Faraday::UploadIO.stub(:new, io) do
              File.stub(:delete, nil) do
                Navigator.stub(:new, navigator) do
                  result, build_version = loader.sideload(**loader_config)
                end
              end
            end
          end
        end
      end

      assert_equal "build_version", build_version
      assert_equal SUCCESS, result

      connection.verify
      faraday.verify
      io.verify
      response.verify
    end

    def test_loader_build_defining_folder_and_files
      root_dir = File.join(File.dirname(__FILE__), "test_files", "loader_test")
      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password",
        init_params: {root_dir: root_dir}
      }
      build_config = {
        content: {
        folders: ["source"],
        files: ["manifest"]
      }
      }
      loader = Loader.new(**device_config)
      outfile = nil
      ManifestManager.stub(:build_version, "build_version") do
        outfile = loader.build(**build_config)
      end
      Zip::File.open(outfile) do |file|
        assert file.find_entry("manifest") != nil
        assert_nil file.find_entry("a")
        assert file.find_entry("source/b") != nil
        assert file.find_entry("source/c/d") != nil
      end
    end
    def test_loader_build_all_contents
      root_dir = File.join(File.dirname(__FILE__), "test_files", "loader_test")
      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password",
        init_params: {root_dir: root_dir}
      }
      build_config = {}
      loader = Loader.new(**device_config)
      outfile = nil
      ManifestManager.stub(:build_version, "build_version") do
        outfile = loader.build(**build_config)
      end
      Zip::File.open(outfile) do |file|
        assert file.find_entry("manifest") != nil
        assert file.find_entry("a") != nil
        assert file.find_entry("source/b") != nil
        assert file.find_entry("source/c/d") != nil
      end
    end

    def test_loader_unload
      connection = Minitest::Mock.new
      faraday = Minitest::Mock.new
      response = Minitest::Mock.new

      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password",
        init_params: {root_dir: "/dev/null"}
      }
      payload = {
        mysubmit: "Delete",
        archive: "",
      }
      path = "/plugin_install"

      faraday.expect(:headers, {})
      faraday.expect(:request, nil, [:digest, device_config[:user], device_config[:password]])
      faraday.expect(:request, nil, [:multipart])
      faraday.expect(:request, nil, [:url_encoded])
      faraday.expect(:adapter, nil, [Faraday.default_adapter])
      connection.expect(:post, response) do |arg1, arg2|
        assert_equal path, arg1
        assert_equal payload[:mysubmit], arg2[:mysubmit]
        assert payload[:archive] === arg2[:archive]
      end
      response.expect(:status, 200)
      response.expect(:body, "Install Success")

      loader = Loader.new(**device_config)
      result = nil
      Faraday.stub(:new, connection, faraday) do
        result = loader.unload
      end

      assert result

      connection.verify
      faraday.verify
      response.verify
    end
    def test_loader_unload_fail
      connection = Minitest::Mock.new
      faraday = Minitest::Mock.new
      response = Minitest::Mock.new

      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password",
        init_params: {root_dir: "/dev/null"}
      }
      payload = {
        mysubmit: "Delete",
        archive: "",
      }
      path = "/plugin_install"

      faraday.expect(:headers, {})
      faraday.expect(:request, nil, [:digest, device_config[:user], device_config[:password]])
      faraday.expect(:request, nil, [:multipart])
      faraday.expect(:request, nil, [:url_encoded])
      faraday.expect(:adapter, nil, [Faraday.default_adapter])
      connection.expect(:post, response) do |arg1, arg2|
        assert_equal path, arg1
        assert_equal payload[:mysubmit], arg2[:mysubmit]
        assert payload[:archive] === arg2[:archive]
      end
      response.expect(:status, 200)
      response.expect(:body, "Install Filed")

      loader = Loader.new(**device_config)
      result = nil
      Faraday.stub(:new, connection, faraday) do
        result = loader.unload
      end

      assert !result

      connection.verify
      faraday.verify
      response.verify
    end
  end
end
