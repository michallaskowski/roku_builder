# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"
module RokuBuilder
  class ManifestTest < Minitest::Test
    def setup
      options = build_options
      @root_dir = test_files_path(ManifestTest)
      @config = Config.new(options: options)
      @config.instance_variable_set(:@parsed, {root_dir: @root_dir})
      FileUtils.cp(File.join(@root_dir, "manifest_template"), File.join(@root_dir, "manifest"))
    end
    def teardown
      path = File.join(@config.parsed[:root_dir], "manifest")
      FileUtils.rm(path) if File.exist?(path)
      @config = nil
    end
    def test_manifest_read
      manifest = Manifest.new(config: @config)
    end
    def test_manifest_read_missing
      FileUtils.rm(File.join(@config.parsed[:root_dir], "manifest"))
      assert_raises ManifestError do
        manifest = Manifest.new(config: @config)
      end
    end
    def test_manifest_tite
      manifest = Manifest.new(config: @config)
      assert_equal "Test", manifest.title
    end
    def test_manifest_build_version
      manifest = Manifest.new(config: @config)
      assert_equal "010101.1", manifest.build_version
    end
    def test_manifest_build_version_zip
      @config.instance_variable_set(:@parsed, {root_dir: File.join(@root_dir, "test.zip")})
      manifest = Manifest.new(config: @config)
      assert_equal "010101.1", manifest.build_version
    end
    def test_manifest_update_attributes
      manifest = Manifest.new(config: @config)
      attributes = {
        title: "New Title"
      }
      manifest.update(attributes: attributes)
      manifest = Manifest.new(config: @config)
      assert_equal attributes[:title], manifest.title
    end
    def test_manifest_update_empty
      manifest = Manifest.new(config: @config)
      attributes = {}
      manifest.update(attributes: attributes)
      assert FileUtils.compare_file(File.join(@root_dir, "manifest"), File.join(@root_dir, "manifest_template"))
    end
    def test_manifest_update_with_comments
      FileUtils.cp(File.join(@root_dir, "manifest_comments"), File.join(@root_dir, "manifest"))
      manifest = Manifest.new(config: @config)
      attributes = {}
      manifest.update(attributes: attributes)
      assert FileUtils.compare_file(File.join(@root_dir, "manifest"), File.join(@root_dir, "manifest_comments"))
    end
    def test_manifest_generate
      FileUtils.rm(File.join(@root_dir, "manifest"))
      attributes = {
        title: "New Title"
      }
      manifest = Manifest.generate(config: @config,  attributes: attributes)
      assert_equal attributes[:title], manifest.title
      assert !!manifest.major_version
      assert !!manifest.minor_version
      assert !!manifest.build_version
      assert !!manifest.mm_icon_focus_fhd
      assert !!manifest.mm_icon_focus_hd
      assert !!manifest.mm_icon_focus_sd
    end
  end
end

