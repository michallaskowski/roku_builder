# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "../test_helper.rb"

module RokuBuilder
  class ProfilerTest < Minitest::Test
    def setup
      Logger.set_testing
      RokuBuilder.setup_plugins
      unless RokuBuilder.plugins.include?(Profiler)
        RokuBuilder.register_plugin(Profiler)
      end
    end
    def test_profiler_stats
      Logger.set_testing
      options = {profile: "stats"}
      config, options = build_config_options_objects(ProfilerTest, options, false)
      waitfor = Proc.new do |telnet_config, &blk|
        assert_equal(/.+/, telnet_config["Match"])
        assert_equal(5, telnet_config["Timeout"])
        txt = "<All_Nodes><NodeA /><NodeB /><NodeC><NodeD /></NodeC></All_Nodes>\n"
        blk.call(txt)
        true
      end
      connection = Minitest::Mock.new
      profiler = Profiler.new(config: config)

      connection.expect(:puts, nil, ["sgnodes all\n"])
      connection.expect(:waitfor, nil, &waitfor)

      Net::Telnet.stub(:new, connection) do
        profiler.stub(:printf, nil) do
          profiler.profile(options: options)
        end
      end

      connection.verify
    end
  end
end
