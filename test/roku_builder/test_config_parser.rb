# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class ConfigParserTest < Minitest::Test
    def test_manifest_config
      options = build_options({
        sideload: true,
        working: true
      })
      config = good_config
      configs = ConfigParser.parse(options: options, config: config)

      assert_equal Hash, config.class
      assert_equal "/tmp", configs[:root_dir]
    end

    def test_manifest_config_in
      options = build_options({
        in: "/dev/null/infile",
        sideload: true
      })
      config = good_config
      configs = ConfigParser.parse(options: options, config: config)

      assert_equal Hash, config.class
      assert_equal "/dev/null/infile", configs[:root_dir]
      assert_equal :in, configs[:stage_config][:method]
    end

    def test_manifest_config_in_expand
      options = build_options({
        in: "./infile",
        sideload: true
      })
      config = good_config
      configs = ConfigParser.parse(options: options, config: config)

      assert_equal Hash, config.class
      assert_equal File.join(Dir.pwd, "infile"), configs[:root_dir]
      assert_equal :in, configs[:stage_config][:method]
    end

    def test_manifest_config_current
      options = build_options({
        current: true,
        sideload: true
      })
      configs = nil
      config = good_config
      Pathname.stub(:pwd, "/dev/null/infile") do
        File.stub(:exist?, true) do
          configs = ConfigParser.parse(options: options, config: config)
        end
      end

      assert_equal Hash, config.class
      assert_equal "/dev/null/infile", configs[:root_dir]
      assert_equal :current, configs[:stage_config][:method]
    end

    def test_setup_project_config_bad_project
      config = good_config
      options = build_options({sideload: true, project: :project3, set_stage: true})
      assert_raises ParseError do
        File.stub(:exist?, true) do
          ConfigParser.parse(options: options, config: config)
        end
      end
    end

    def test_setup_project_config_current
      options = build_options({ sideload: true, current: true })
      config = good_config
      configs = nil
      File.stub(:exist?, true) do
        configs = ConfigParser.parse(options: options, config: config)
      end
      project = configs[:project_config]
      assert_equal Pathname.pwd.to_s, project[:directory]
      assert_equal :current, project[:stage_method]
      assert_nil project[:folders]
      assert_nil project[:files]
    end

    def test_setup_project_config_good_project_dir
      config = good_config
      options = build_options({sideload: true, project: :project1, set_stage: true})
      File.stub(:exist?, true) do
        ConfigParser.parse(options: options, config: config)
      end
    end

    def test_setup_project_config_bad_project_dir
      config = good_config
      config[:projects][:project1][:directory] = "/dev/null"
      options = build_options({sideload: true, project: :project1, working: true})
      assert_raises ParseError do
        File.stub(:exist?, true) do
          ConfigParser.parse(options: options, config: config)
        end
      end
    end

    def test_setup_project_config_bad_child_project_dir
      config = good_config
      config[:projects][:project_dir] = "/tmp"
      config[:projects][:project1][:directory] = "bad"
      options = build_options({sideload: true, project: :project1, working: true})
      assert_raises ParseError do
        File.stub(:exist?, true) do
          ConfigParser.parse(options: options, config: config)
        end
      end
    end

    def test_setup_project_config_bad_parent_project_dir
      config = good_config
      config[:projects][:project_dir] = "/bad"
      config[:projects][:project1][:directory] = "good"
      options = build_options({sideload: true, project: :project1, set_stage: true})
      assert_raises ParseError do
        File.stub(:exist?, true) do
          ConfigParser.parse(options: options, config: config)
        end
      end
    end

    def test_setup_stage_config_bad_stage
      config = good_config
      options = build_options({sideload: true, project: :project1, stage: :bad, set_stage: true})
      assert_raises ParseError do
        File.stub(:exist?, true) do
          ConfigParser.parse(options: options, config: config)
        end
      end
    end

    def test_setup_stage_config_bad_method
      config = good_config
      config[:projects][:project1][:stage_method] = :bad
      options = build_options({sideload: true, project: :project1, set_stage: true})
      assert_raises ParseError do
        File.stub(:exist?, true) do
          ConfigParser.parse(options: options, config: config)
        end
      end
    end

    def test_setup_stage_config_missing_method
      config = good_config
      config[:projects][:project1][:stage_method] = nil
      options = build_options({sideload: true, project: :project1, set_stage: true})
      assert_raises ParseError do
        File.stub(:exist?, true) do
          ConfigParser.parse(options: options, config: config)
        end
      end
    end

    def test_setup_stage_config_script
      config = good_config
      config[:projects][:project1][:stage_method] = :script
      config[:projects][:project1][:stages][:production][:script] = {stage: "script", unstage: "script"}
      options = build_options({stage: "production", sideload: true, set_stage: true})
      parsed = ConfigParser.parse(options: options, config: config)
      assert_equal parsed[:project_config][:stages][:production][:script], config[:projects][:project1][:stages][:production][:script]
    end

    def test_setup_stage_config_git_ref
      config = good_config
      options = build_options({stage: "production", ref: "git-ref", sideload: true})
      parsed = ConfigParser.parse(options: options, config: config)
      assert_equal options[:ref], parsed[:stage_config][:key]
    end

    def test_manifest_config_project_select
      options = build_options({ sideload: true, working: true })
      config = good_config
      configs = nil
      Pathname.stub(:pwd, Pathname.new("/dev/nuller")) do
        configs = ConfigParser.parse(options: options, config: config)
      end
      assert_equal Hash, config.class
      assert_equal "/tmp", configs[:project_config][:directory]
    end

    def test_manifest_config_project_directory
      options = build_options({
        sideload: true,
        working: true
      })
      config = good_config
      config[:projects][:project_dir] = "/tmp"
      config[:projects][:project1][:directory] = "project1"
      config[:projects][:project2][:directory] = "project2"

      configs = nil

      Dir.stub(:exist?, true) do
        configs = ConfigParser.parse(options: options, config: config)
      end

      assert_equal Hash, config.class
      assert_equal "/tmp/project1", configs[:project_config][:directory]
    end

    def test_manifest_config_project_directory_select
      options = build_options({sideload: true, working: true})
      config = good_config
      config[:projects][:project_dir] = "/tmp"
      config[:projects][:project1][:directory] = "project1"
      config[:projects][:project2][:directory] = "project2"

      configs = nil
      Pathname.stub(:pwd, Pathname.new("/tmp/project2")) do
        Dir.stub(:exist?, true) do
          configs = ConfigParser.parse(options: options, config: config)
        end
      end

      assert_equal Hash, config.class
      assert_equal "/tmp/project2", configs[:project_config][:directory]
    end

    def test_key_config_key_directory
      tmp_file = Tempfile.new("pkg")
      options = build_options({key: true, project: :project2, set_stage: true})
      config = good_config
      config[:keys][:key_dir] = File.dirname(tmp_file.path)
      config[:keys][:a][:keyed_pkg] = File.basename(tmp_file.path)

      configs = ConfigParser.parse(options: options, config: config)

      assert_equal Hash, config.class
      assert_equal tmp_file.path, configs[:key][:keyed_pkg]
      tmp_file.close
    end

    def test_key_config_key_directory_bad
      tmp_file = Tempfile.new("pkg")
      options = build_options({key: true, project: :project2, set_stage: true})
      config = good_config
      config[:keys][:key_dir] = "/bad"
      config[:keys][:a][:keyed_pkg] = File.basename(tmp_file.path)

      assert_raises ParseError do
        ConfigParser.parse(options: options, config: config)
      end
    end

    def test_key_config_key_path_bad
      tmp_file = Tempfile.new("pkg")
      options = build_options({key: true, project: :project2, set_stage: true})
      config = good_config
      config[:keys][:key_dir] = File.dirname(tmp_file.path)
      config[:keys][:a][:keyed_pkg] = File.basename(tmp_file.path)+".bad"

      assert_raises ParseError do
        ConfigParser.parse(options: options, config: config)
      end
    end

    def test_key_config_bad_key
      options = build_options({key: true, project: :project1, set_stage: true})
      config = good_config
      config[:projects][:project1][:stages][:production][:key] = "bad"

      assert_raises ParseError do
        ConfigParser.parse(options: options, config: config)
      end
    end

    def test_setup_sideload_config
      config = good_config
      options = build_options({sideload: true, working: true})
      parsed = ConfigParser.parse(options: options, config: config)

      refute_nil parsed[:sideload_config]
      refute_nil parsed[:sideload_config][:content]
      refute_nil parsed[:build_config]
      refute_nil parsed[:build_config][:content]
      refute_nil parsed[:init_params][:loader]
      refute_nil parsed[:init_params][:loader][:root_dir]

      assert_nil parsed[:sideload_config][:content][:excludes]
      assert_nil parsed[:sideload_config][:update_manifest]
      assert_nil parsed[:sideload_config][:infile]
    end
    def test_setup_sideload_config_exclude
      config = good_config
      config[:projects][:project1][:excludes] = []
      options = build_options({sideload: true, working: true})
      parsed = ConfigParser.parse(options: options, config: config)
      assert_nil parsed[:sideload_config][:content][:excludes]

      options = build_options({build: true, working: true})
      parsed = ConfigParser.parse(options: options, config: config)
      refute_nil parsed[:sideload_config][:content][:excludes]

      options = build_options({package: true, set_stage: true})
      parsed = ConfigParser.parse(options: options, config: config)
      refute_nil parsed[:sideload_config][:content][:excludes]

      options = build_options({sideload: true, working: true, exclude: true})
      parsed = ConfigParser.parse(options: options, config: config)
      refute_nil parsed[:sideload_config][:content][:excludes]
    end

    def test_deeplink_app_config
      config = good_config
      options = build_options({deeplink: "a:b", app_id: "xxxxxx"})
      parsed = ConfigParser.parse(options: options, config: config)

      assert_equal parsed[:deeplink_config][:options], options[:deeplink]
      assert_equal parsed[:deeplink_config][:app_id], options[:app_id]
    end

    def test_monitor_config
      config = good_config
      options = build_options({monitor: "main", regexp: "^A$"})
      parsed = ConfigParser.parse(options: options, config: config)
      refute_nil parsed[:monitor_config][:regexp]
      assert parsed[:monitor_config][:regexp].match("A")
    end
    def test_outfile_config_default
      config = good_config
      options = build_options({build: true, working: true, out: nil})
      parsed = ConfigParser.parse(options: options, config: config)

      refute_nil parsed[:out]
      refute_nil parsed[:out][:folder]
      assert_nil parsed[:out][:file]
      assert_equal "/tmp", parsed[:out][:folder]
    end
    def test_outfile_config_folder
      config = good_config

      options = build_options({build: true, working: true, out: "/home/user"})
      parsed = ConfigParser.parse(options: options, config: config)
      refute_nil parsed[:out]
      refute_nil parsed[:out][:folder]
      assert_nil parsed[:out][:file]
      assert_equal "/home/user", parsed[:out][:folder]
    end
    def test_outfile_config_pkg
      config = good_config

      options = build_options({build: true, working: true, out: "/home/user/file.pkg"})
      parsed = ConfigParser.parse(options: options, config: config)
      refute_nil parsed[:out]
      refute_nil parsed[:out][:folder]
      refute_nil parsed[:out][:file]
      assert_equal "/home/user", parsed[:out][:folder]
      assert_equal "file.pkg", parsed[:out][:file]
    end
    def test_outfile_config_zip
      config = good_config

      options = build_options({build: true, working: true, out: "/home/user/file.zip"})
      parsed = ConfigParser.parse(options: options, config: config)
      refute_nil parsed[:out]
      refute_nil parsed[:out][:folder]
      refute_nil parsed[:out][:file]
      assert_equal "/home/user", parsed[:out][:folder]
      assert_equal "file.zip", parsed[:out][:file]
    end
    def test_outfile_config_jpg
      config = good_config

      options = build_options({build: true, working: true, out: "/home/user/file.jpg"})
      parsed = ConfigParser.parse(options: options, config: config)
      refute_nil parsed[:out]
      refute_nil parsed[:out][:folder]
      refute_nil parsed[:out][:file]
      assert_equal "/home/user", parsed[:out][:folder]
      assert_equal "file.jpg", parsed[:out][:file]
    end
    def test_outfile_config_default_jpg
      config = good_config

      options = build_options({build: true, working: true, out: "file.jpg"})
      parsed = ConfigParser.parse(options: options, config: config)
      refute_nil parsed[:out]
      refute_nil parsed[:out][:folder]
      refute_nil parsed[:out][:file]
      assert_equal "/tmp", parsed[:out][:folder]
      assert_equal "file.jpg", parsed[:out][:file]
    end
  end
end
