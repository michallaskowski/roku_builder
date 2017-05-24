# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class LinkerTest < Minitest::Test
    def setup
      @config = build_config_object(LinkerTest)
      @requests = []
    end
    def teardown
      @requests.each {|req| remove_request_stub(req)}
    end
    def test_linker_link

      options = 'a:A, b:B:C, d:a\b'

      @requests.push(stub_request(:post, "http://192.168.0.100:8060/launch/dev?a=A&b=B:C&d=a%5Cb").
        to_return(status: 200, body: "", headers: {}))

      linker = Linker.new(config: @config)
      success = linker.launch(options: options)

      assert success
    end
    def test_linker_link_nothing

      @requests.push(stub_request(:post, "http://192.168.0.100:8060/launch/dev").
        to_return(status: 200, body: "", headers: {}))
      options = ''
      linker = Linker.new(config: @config)
      success = linker.launch(options: options)

      assert success
    end

    def test_linker_list
      body = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<apps>\n\t
      <app id=\"31012\" type=\"menu\" version=\"1.6.3\">Movie Store and TV Store</app>\n\t
      <app id=\"31863\" type=\"menu\" version=\"1.2.6\">Roku Home News</app>\n\t
      <app id=\"65066\" type=\"appl\" version=\"1.3.0\">Nick</app>\n\t
      <app id=\"68161\" type=\"appl\" version=\"1.3.0\">Nick</app>\n\t
      </apps>\n"
      @requests.push(stub_request(:get, "http://192.168.0.100:8060/query/apps").
        to_return(status: 200, body: body, headers: {}))

      linker = Linker.new(config: @config)

      print_count = 0
      did_print = Proc.new { |msg| print_count+=1 }

      linker.stub(:printf, did_print) do
        linker.list
      end

      assert_equal 6, print_count
    end
  end
end
