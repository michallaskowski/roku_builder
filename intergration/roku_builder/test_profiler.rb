# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class ProfilerIntergrationTest < Minitest::Test
    include Helpers
    def setup
      @config = build_config(ProfilerIntergrationTest)
      @uuid = SecureRandom.uuid
      build_uuid_script
    end
    def teardown
      FileUtils.rm(@config) if File.exist?(@config)
      cleanup_uuid_script
    end
    def test_profile
      `#{roku} --sideload --working`
      assert_log @uuid
      output = `#{roku} --profile stats`
      assert output =~ /Name \| Count/
      assert output =~ /Total \|\s*5/
      assert output =~ /Default \|\s*1/
      assert output =~ /RectangleExample \|\s*1/
      assert output =~ /Poster \|\s*1/
      assert output =~ /Node \|\s*1/
      assert output =~ /Rectangle \|\s*1/
    end
  end
end
