# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class ProfilerTest < Minitest::Test
    def test_profiler_stats
      Logger.set_testing
      config = build_config_object(ProfilerTest)
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
          profiler.run(command: :stats)
        end
      end

      connection.verify
    end
  end
end
