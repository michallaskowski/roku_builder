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
      warnings = test_manifest
      assert_equal Array, warnings.class
    end
    def test_manifest_duplicate_attribute
      warnings = test_manifest("manifest_duplicate_attribute")
      assert_equal 1, warnings.count
      assert_match(/title/, warnings[0][:message])
      assert_equal 2, warnings[0][:line]
      assert_equal "manifest", warnings[0][:path]
    end
    def test_manifest_depricated_attribute
      warnings = test_manifest("manifest_depricated_attribute")
      assert_equal 1, warnings.count
      assert_match(/subtitle/, warnings[0][:message])
      assert_equal 2, warnings[0][:line]
      assert_equal "manifest", warnings[0][:path]
    end
    def test_manifest_empty_value
      warnings = test_manifest("manifest_empty_value")
      assert_equal 1, warnings.count
      assert_match(/empty/, warnings[0][:message])
      assert_equal 9, warnings[0][:line]
      assert_equal "manifest", warnings[0][:path]
    end
    def test_manifest_invalid_value_integer
      warnings = test_manifest("manifest_invalid_value_integer")
      assert_equal 1, warnings.count
      assert_match(/major_version/, warnings[0][:message])
      assert_match(/bad/, warnings[0][:message])
      assert_equal 2, warnings[0][:line]
      assert_equal "manifest", warnings[0][:path]
    end
    def test_manifest_invalid_value_float
      warnings = test_manifest("manifest_invalid_value_float")
      assert_equal 1, warnings.count
      assert_match(/rsg_version/, warnings[0][:message])
      assert_match(/1/, warnings[0][:message])
      assert_equal 9, warnings[0][:line]
      assert_equal "manifest", warnings[0][:path]
    end
    def test_manifest_invalid_value_negative
      warnings = test_manifest("manifest_invalid_value_negative")
      assert_equal 1, warnings.count
      assert_match(/major_version/, warnings[0][:message])
      assert_match(/-1/, warnings[0][:message])
      assert_equal 2, warnings[0][:line]
      assert_equal "manifest", warnings[0][:path]
    end
    def test_manifest_invalid_value_not_equal
      warnings = test_manifest("manifest_invalid_value_not_equal")
      assert_equal 1, warnings.count
      assert_match(/build_version/, warnings[0][:message])
      assert_match(/0/, warnings[0][:message])
      assert_equal 4, warnings[0][:line]
      assert_equal "manifest", warnings[0][:path]
    end
    def test_manifest_invalid_value_equals
      warnings = test_manifest("manifest_invalid_value_equals")
      assert_equal 1, warnings.count
      assert_match(/screensaver_private/, warnings[0][:message])
      assert_match(/2/, warnings[0][:message])
      assert_equal 9, warnings[0][:line]
      assert_equal "manifest", warnings[0][:path]
    end
    def test_manifest_invalid_value_starts_with
      warnings = test_manifest("manifest_invalid_value_starts_with")
      refute_equal 0, warnings.count
      assert_match(/mm_icon_focus_hd/, warnings[0][:message])
      assert_match(/bad/, warnings[0][:message])
      assert_match(/invalid value/, warnings[0][:message])
      assert_equal 5, warnings[0][:line]
      assert_equal "manifest", warnings[0][:path]
    end
    def test_manifest_has_value
      warnings = test_manifest("manifest_has_value")
      assert_equal 1, warnings.count
      assert_match(/rsg_version/, warnings[0][:message])
      assert_match(/1.0/, warnings[0][:message])
      assert_equal 9, warnings[0][:line]
      assert_equal "manifest", warnings[0][:path]
    end
    def test_manifest_missing_file
      warnings = test_manifest("manifest_missing_file")
      assert_equal 1, warnings.count
      assert_match(/mm_icon_focus_hd/, warnings[0][:message])
      assert_match(/missing.png/, warnings[0][:message])
      assert_equal 5, warnings[0][:line]
      assert_equal "manifest", warnings[0][:path]
    end
    def test_manifest_missing_attribute
      warnings = test_manifest("manifest_missing_attribute")
      assert_equal 1, warnings.count
      assert_match(/title/, warnings[0][:message])
      assert_equal "manifest", warnings[0][:path]
      refute warnings[0][:line]
    end
    def test_manifest_incorrect_image_resolution
      warnings = test_manifest("manifest_incorrect_image_resolution")
      assert_equal 1, warnings.count
      assert_match(/mm_icon_focus_hd/, warnings[0][:message])
      assert_match(/too_small.png/, warnings[0][:message])
      assert_match(/336x210/, warnings[0][:message])
      assert_match(/1x1/, warnings[0][:message])
      assert_equal 5, warnings[0][:line]
      assert_equal "manifest", warnings[0][:path]
    end


    private

    def test_manifest(manifest_file = nil)
      if manifest_file
        FileUtils.cp(File.join(@root_dir, manifest_file), File.join(@root_dir, "manifest"))
      end
      analyzer = Analyzer.new(config: @config)
      analyzer.analyze(options: @options)
    end

    def print_all(warnings)
      warnings.each do |warning|
        puts warning[:message]
      end
    end
  end
end

