# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "../test_helper.rb"

module RokuBuilder
  class PackagerTest < Minitest::Test
    def setup
      @config = build_config_object(PackagerTest)
      @package_config ={
        app_name_version: "app_name",
        out_file: "out_file",
        password: "password"
      }
      @requests = []
    end
    def teardown
      @requests.each {|req| remove_request_stub(req)}
    end
    def test_packager_package_failed
      @requests.push(stub_request(:post, "http://192.168.0.100/plugin_package").
        to_return(status: 200, body: "Failed: Error.", headers: {}))
      packager = Packager.new(config: @config)
      result = packager.package(**@package_config)

      assert_equal "Failed: Error.", result
    end

    def test_packager_package
      io = Minitest::Mock.new

      body = "<a href=\"pkgs\">pkg_url</a>"
      @requests.push(stub_request(:post, "http://192.168.0.100/plugin_package").
        to_return(status: 200, body: body, headers: {}).times(2))

      body = "package_body"
      @requests.push(stub_request(:get, "http://192.168.0.100/pkgs/pkg_url").
        to_return(status: 200, body: body, headers: {}))

      io.expect(:write, nil, ["package_body"])

      packager = Packager.new(config: @config)
      result = nil
      Time.stub(:now, Time.at(0)) do
        File.stub(:open, nil, io) do
          result = packager.package(**@package_config)
        end
      end

      assert_equal true, result
      io.verify
    end
  end
end
