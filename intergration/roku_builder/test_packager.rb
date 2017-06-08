# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class PackagerIntergrationTest < Minitest::Test
    include Helpers
    def setup
      @config = build_config(PackagerIntergrationTest)
      @uuid = SecureRandom.uuid
      build_uuid_script
    end
    def teardown
      FileUtils.rm(@config) if File.exist?(@config)
    end
    def test_package
      target = File.join(testfiles_path(PackagerIntergrationTest), "pkg.pkg")
      FileUtils.rm(target) if File.exist?(target)
      output = `#{roku} --package --stage production --out #{target}`
      refute(/WARN: Missing File/.match(output))
      wait_assert {File.exist?(target)}
      FileUtils.rm(target) if File.exist?(target)
    end
    def test_key
      target = File.join(testfiles_path(PackagerIntergrationTest), "pkg.pkg")
      `#{roku} --genkey --out #{target}`
      output = `#{roku} --key --stage production --debug`
      assert output =~ /-> e8efc6f5efd5b4991be53ccf3e273f04535bfb4c/
      FileUtils.rm(target) if File.exist?(target)
    end
    def test_genkey
      target = File.join(testfiles_path(PackagerIntergrationTest), "pkg.pkg")
      `#{roku} --genkey --out #{target}`
      wait_assert {File.exist?(target)}
      FileUtils.rm(target) if File.exist?(target)
    end
  end
end

