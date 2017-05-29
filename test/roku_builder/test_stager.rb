# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class StagerTest < Minitest::Test

    def test_stager_method
      root_dir = File.join(File.dirname(__FILE__), "test_files", "stager_test")
      stager_config = {
        method: :working,
        root_dir: root_dir
      }
      stager = Stager.new(**stager_config)
      assert_equal stager_config[:method], stager.method
    end

    def test_stager_stage_working
      root_dir = File.join(File.dirname(__FILE__), "test_files", "stager_test")
      stager_config = {
        method: :working,
        root_dir: root_dir
      }
      stager = Stager.new(**stager_config)
      assert stager.stage
      assert stager.unstage
    end

    def test_stager_stage_current
      root_dir = File.join(File.dirname(__FILE__), "test_files", "stager_test")
      stager_config = {
        method: :current,
        root_dir: root_dir
      }
      stager = Stager.new(**stager_config)
      assert stager.stage
      assert stager.unstage
    end

    def test_stager_stage_in
      root_dir = File.join(File.dirname(__FILE__), "test_files", "stager_test")
      stager_config = {
        method: :in,
        root_dir: root_dir
      }
      stager = Stager.new(**stager_config)
      assert stager.stage
      assert stager.unstage
    end

    def test_stager_stage_git_stash
      root_dir = File.join(File.dirname(__FILE__), "test_files", "stager_test")
      branch_name = 'branch'
      git = Minitest::Mock.new
      branch = Minitest::Mock.new
      stashes = Minitest::Mock.new
      stash = Minitest::Mock.new

      stager_config = {
        method: :git,
        root_dir: root_dir,
        key: branch_name
      }

      git.expect(:current_branch, 'other_branch')
      git.expect(:current_branch, 'other_branch')
      git.expect(:branch, branch)
      branch.expect(:stashes, stashes)
      stashes.expect(:save, true, ["roku-builder-temp-stash"])
      git.expect(:checkout, nil, [branch_name])
      git.expect(:branch, branch)
      branch.expect(:stashes, [stash])
      git.expect(:checkout, nil, ['other_branch'])
      git.expect(:branch, branch)
      stash.expect(:message, "roku-builder-temp-stash")
      branch.expect(:stashes, stashes)
      stashes.expect(:pop, nil, ["stash@{0}"])

      Git.stub(:open, git) do
        stager = Stager.new(**stager_config)
        assert stager.stage
        assert stager.unstage
      end
      git.verify
      branch.verify
      stashes.verify
      stash.verify
    end

    def test_stager_stage_git_no_stash
      root_dir = File.join(File.dirname(__FILE__), "test_files", "stager_test")
      branch_name = 'branch'
      git = Minitest::Mock.new
      branch = Minitest::Mock.new
      stashes = Minitest::Mock.new

      stager_config = {
        method: :git,
        root_dir: root_dir,
        key: branch_name
      }

      git.expect(:current_branch, 'other_branch')
      git.expect(:current_branch, 'other_branch')
      git.expect(:branch, branch)
      branch.expect(:stashes, stashes)
      stashes.expect(:save, nil, ["roku-builder-temp-stash"])
      git.expect(:checkout, nil, [branch_name])

      git.expect(:checkout, nil, ['other_branch'])
      git.expect(:branch, branch)
      branch.expect(:stashes, [])

      Git.stub(:open, git) do
        stager = Stager.new(**stager_config)
        assert stager.stage
        assert stager.unstage
      end
      git.verify
      branch.verify
      stashes.verify
    end

    def test_stager_stage_git_error_stage
      root_dir = File.join(File.dirname(__FILE__), "test_files", "stager_test")
      branch_name = 'branch'
      git = Minitest::Mock.new
      branch = Minitest::Mock.new
      stashes = Minitest::Mock.new
      stash = Minitest::Mock.new

      stager_config = {
        method: :git,
        root_dir: root_dir,
        key: branch_name
      }

      def git.checkout(branch)
        raise Git::GitExecuteError.new
      end

      git.expect(:current_branch, 'other_branch')
      git.expect(:current_branch, 'other_branch')
      git.expect(:branch, branch)
      branch.expect(:stashes, stashes)
      stashes.expect(:save, true, ["roku-builder-temp-stash"])
      git.expect(:branch, branch)
      branch.expect(:stashes, [stash])
      git.expect(:branch, branch)
      stash.expect(:message, "roku-builder-temp-stash")
      branch.expect(:stashes, stashes)
      stashes.expect(:pop, nil, ["stash@{0}"])

      Git.stub(:open, git) do
        stager = Stager.new(**stager_config)
        assert !stager.stage
        assert stager.unstage
      end
      git.verify
      branch.verify
      stashes.verify
      stash.verify
    end

    def test_stager_stage_git_error_unstage
      root_dir = File.join(File.dirname(__FILE__), "test_files", "stager_test")
      branch_name = 'branch'
      git = Minitest::Mock.new
      logger = Minitest::Mock.new

      stager_config = {
        method: :git,
        root_dir: root_dir,
        key: branch_name
      }
      Logger.class_variable_set(:@@instance, logger)

      def git.checkout(branch)
        raise Git::GitExecuteError.new
      end

      logger.expect(:error, nil, ["Branch or ref does not exist"])

      Git.stub(:open, git) do
        stager = Stager.new(**stager_config)
        stager.instance_variable_set(:@current_branch, "branch")
        assert !stager.unstage
      end
      git.verify
      logger.verify
      Logger.set_testing
    end

    def test_stager_stage_script
      root_dir = File.join(File.dirname(__FILE__), "test_files", "stager_test")
      stager_config = {
        method: :script,
        key: {stage: "stage_script", unstage: "unstage_script"},
        root_dir: root_dir
      }
      RokuBuilder.stub(:system, nil) do
        stager = Stager.new(**stager_config)
        assert stager.stage
        assert stager.unstage
      end
    end

    def test_stager_save_state
      root_dir = File.join(File.dirname(__FILE__), "test_files", "stager_test")
      branch_name = 'branch'
      git = Minitest::Mock.new
      branch = Minitest::Mock.new
      stashes = Minitest::Mock.new
      pstore = Minitest::Mock.new

      stager_config = {
        method: :git,
        root_dir: root_dir,
        key: branch_name
      }

      git.expect(:current_branch, 'other_branch')
      git.expect(:current_branch, 'other_branch')
      git.expect(:branch, branch)
      branch.expect(:stashes, stashes)
      stashes.expect(:save, 'stash', ["roku-builder-temp-stash"])
      git.expect(:checkout, nil, [branch_name])

      pstore.expect(:transaction, nil) do |&block|
      block.call
      end
      pstore.expect(:[]=, nil, [:current_branch, 'other_branch'])


      Git.stub(:open, git) do
        PStore.stub(:new, pstore) do
          stager = Stager.new(**stager_config)
          assert stager.stage
        end
      end
      git.verify
      branch.verify
      stashes.verify
      pstore.verify
    end

    def test_stager_load_state
      root_dir = File.join(File.dirname(__FILE__), "test_files", "stager_test")
      branch_name = 'branch'
      git = Minitest::Mock.new
      branch = Minitest::Mock.new
      stashes = Minitest::Mock.new
      stash = Minitest::Mock.new
      pstore = Minitest::Mock.new

      stager_config = {
        method: :git,
        root_dir: root_dir,
        key: branch_name
      }

      pstore.expect(:transaction, nil) do |&block|
      block.call
      end
      git.expect(:branches, ['other_branch'])
      pstore.expect(:[], 'other_branch', [:current_branch])
      pstore.expect(:[]=, nil, [:current_branch, nil])

      git.expect(:branch, branch)
      branch.expect(:stashes, [stash])
      git.expect(:checkout, nil, ['other_branch'])
      git.expect(:branch, branch)
      stash.expect(:message, "roku-builder-temp-stash")
      branch.expect(:stashes, stashes)
      stashes.expect(:pop, nil, ["stash@{0}"])

      Git.stub(:open, git) do
        PStore.stub(:new, pstore) do
          stager = Stager.new(**stager_config)
          assert stager.unstage
        end
      end
      git.verify
      branch.verify
      stashes.verify
      stash.verify
      pstore.verify
    end

    def test_stager_load_second_state
      root_dir = File.join(File.dirname(__FILE__), "test_files", "stager_test")
      branch_name = 'branch'
      git = Minitest::Mock.new
      branch = Minitest::Mock.new
      stashes = Minitest::Mock.new
      stash = Minitest::Mock.new
      other_stash = Minitest::Mock.new
      pstore = Minitest::Mock.new

      stager_config = {
        method: :git,
        root_dir: root_dir,
        key: branch_name
      }

      pstore.expect(:transaction, nil) do |&block|
      block.call
      end
      git.expect(:branches, ['other_branch'])
      pstore.expect(:[], 'other_branch', [:current_branch])
      pstore.expect(:[]=, nil, [:current_branch, nil])

      git.expect(:branch, branch)
      branch.expect(:stashes, [other_stash, stash])
      git.expect(:checkout, nil, ['other_branch'])
      git.expect(:branch, branch)
      stash.expect(:message, "roku-builder-temp-stash")
      other_stash.expect(:message, "random_messgae")
      branch.expect(:stashes, stashes)
      stashes.expect(:pop, nil, ["stash@{1}"])

      Git.stub(:open, git) do
        PStore.stub(:new, pstore) do
          stager = Stager.new(**stager_config)
          assert stager.unstage
        end
      end
      git.verify
      branch.verify
      stashes.verify
      stash.verify
      other_stash.verify
      pstore.verify
    end
  end
end
