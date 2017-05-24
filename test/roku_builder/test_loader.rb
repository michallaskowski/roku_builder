# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class LoaderTest < Minitest::Test
    def setup
      Logger.set_testing
      options = build_options
      @config = Config.new(options: options)
      @root_dir = test_files_path(LoaderTest)
      @device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password",
      }
      @config.instance_variable_set(:@parsed, {root_dir: @root_dir, device_config: @device_config, init_params: {}})
      FileUtils.cp(File.join(@root_dir, "manifest_template"), File.join(@root_dir, "manifest"))
      @request_stubs = []
    end
    def teardown
      FileUtils.rm(File.join(@root_dir, "manifest"))
      @request_stubs.each {|req| remove_request_stub(req)}
    end
    def test_loader_sideload
      loader_config = {
        content: {
          folders: ["source"],
          files: ["manifest"]
        }
      }

      @request_stubs.push(stub_request(:post, "http://#{@device_config[:ip]}:8060/keypress/Home").
        to_return(status: 200, body: "", headers: {}))
      @request_stubs.push(stub_request(:post, "http://#{@device_config[:ip]}/plugin_install").
        to_return(status: 200, body: "Install Success", headers: {}))

      loader = Loader.new(config: @config)
      result, build_version = loader.sideload(**loader_config)

      assert_equal "010101.1", build_version
      assert_equal SUCCESS, result
    end
    def test_loader_sideload_infile
      infile = File.join(@root_dir, "test.zip")
      @config.instance_variable_set(:@parsed, {root_dir: infile, device_config: @device_config, init_params: {}})
      loader_config = {
        infile: infile
      }

      @request_stubs.push(stub_request(:post, "http://#{@device_config[:ip]}:8060/keypress/Home").
        to_return(status: 200, body: "", headers: {}))
      @request_stubs.push(stub_request(:post, "http://#{@device_config[:ip]}/plugin_install").
        to_return(status: 200, body: "Install Success", headers: {}))

      loader = Loader.new(config: @config)
      result, build_version = loader.sideload(**loader_config)

      assert_equal "010101.1", build_version
      assert_equal SUCCESS, result
    end
    def test_loader_sideload_update
      loader_config = {
        update_manifest: true,
        content: {
          folders: ["source"],
          files: ["manifest"]
        }
      }
      
      @request_stubs.push(stub_request(:post, "http://#{@device_config[:ip]}:8060/keypress/Home").
        to_return(status: 200, body: "", headers: {}))
      @request_stubs.push(stub_request(:post, "http://#{@device_config[:ip]}/plugin_install").
        to_return(status: 200, body: "Install Success", headers: {}))

      loader = Loader.new(config: @config)
      result, build_version = loader.sideload(**loader_config)

      assert_equal "#{Time.now.strftime("%m%d%y")}.2", build_version
      assert_equal SUCCESS, result

    end

    def test_loader_build_defining_folder_and_files
      build_config = {
        content: {
          folders: ["source"],
          files: ["manifest"]
        }
      }
      loader = Loader.new(config: @config)
      outfile = loader.build(**build_config)
      Zip::File.open(outfile) do |file|
        assert file.find_entry("manifest") != nil
        assert_nil file.find_entry("a")
        assert file.find_entry("source/b") != nil
        assert file.find_entry("source/c/d") != nil
      end
    end
    def test_loader_build_all_contents
      build_config = {}
      loader = Loader.new(config: @config)
      outfile = loader.build(**build_config)
      Zip::File.open(outfile) do |file|
        assert file.find_entry("manifest") != nil
        assert file.find_entry("a") != nil
        assert file.find_entry("source/b") != nil
        assert file.find_entry("source/c/d") != nil
      end
    end

    def test_loader_unload
      payload = {
        mysubmit: "Delete",
        archive: "",
      }

      @request_stubs.push(stub_request(:post, "http://#{@device_config[:ip]}/plugin_install").
        to_return(status: 200, body: "Install Success", headers: {}))

      loader = Loader.new(config: @config)
      result = loader.unload

      assert result
    end
    def test_loader_unload_fail
      payload = {
        mysubmit: "Delete",
        archive: "",
      }

      @request_stubs.push(stub_request(:post, "http://#{@device_config[:ip]}/plugin_install").
        to_return(status: 200, body: "Install Failed", headers: {}))

      loader = Loader.new(config: @config)
      result = loader.unload

      assert !result
    end
  end
end
