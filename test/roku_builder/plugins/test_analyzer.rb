# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "../test_helper.rb"

module RokuBuilder
  class AnalyzerTest < Minitest::Test
    def setup
      Logger.set_testing
      RokuBuilder.class_variable_set(:@@dev, false)
      RokuBuilder.setup_plugins
      register_plugins(Analyzer)
      @config, @options = build_config_options_objects(AnalyzerTest, {analyze: true, working: true, quiet_analyze: true}, false)
      @root_dir = @config.root_dir
      @device_config = @config.device_config
      FileUtils.cp(File.join(@root_dir, "manifest_template"), File.join(@root_dir, "manifest"))
      @request_stubs = []
      analyzer_config = nil
      File.open(File.join(@root_dir, "analyzer_config.json")) do |file|
        analyzer_config = file.read
      end
      @request_stubs.push(stub_request(:get, "http://devtools.web.roku.com/static-code-analyzer/config.json").
        to_return(status: 200, body: analyzer_config, headers: {}))
    end
    def teardown
      FileUtils.rm(File.join(@root_dir, "manifest"))
      @request_stubs.each {|req| remove_request_stub(req)}
    end
    def test_analyzer_parse_commands
      parser = OptionParser.new
      options = {}
      Analyzer.parse_options(parser: parser, options: options)
      argv = ["roku", "--analyze"]
      parser.parse! argv
      assert options[:analyze]
    end
    def test_clean_app
      analyzer = Analyzer.new(config: @config)
      warnings = analyzer.analyze(options: @options)
      assert_equal Array, warnings.class
    end
    def test_manifest_duplicate_attribute
      FileUtils.cp(File.join(@root_dir, "manifest_duplicate_attribute"), File.join(@root_dir, "manifest"))
      analyzer = Analyzer.new(config: @config)
      warnings = analyzer.analyze(options: @options)
      assert_equal 1, warnings.count
      assert_match /title/, warnings[0][:message]
    end
    def test_manifest_depricated_attribute
      FileUtils.cp(File.join(@root_dir, "manifest_depricated_attribute"), File.join(@root_dir, "manifest"))
      analyzer = Analyzer.new(config: @config)
      warnings = analyzer.analyze(options: @options)
      assert_equal 1, warnings.count
      assert_match /subtitle/, warnings[0][:message]
    end
  end
end

