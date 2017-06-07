# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class InspectorIntergrationTest < Minitest::Test
    def setup
      @config = build_config(InspectorIntergrationTest)
    end
    def teardown
      FileUtils.rm(@config) if File.exist?(@config)
    end
    def test_inspector
      target = File.join(test_files_path(InspectorIntergrationTest), "test.pkg")
      output = `bin/roku --inspect --in #{target} --password CvOqcutO3X419INdUbOyqw== --config #{@config}`
      assert output =~ /App Name:/
      assert output =~ /Dev ID:/
      assert output =~ /Creation Date:/
      assert output =~ /dev.zip:/
    end
  end
end

