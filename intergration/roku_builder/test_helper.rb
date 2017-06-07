# ********** Copyright Viacom, Inc. Apache 2.0 **********

require "simplecov"
require "coveralls"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter::new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
])
SimpleCov.start

require "byebug"
require "roku_builder"
require "minitest/autorun"
require "minitest/utils"


def test_files_path(klass)
  klass = klass.to_s.split("::")[1].underscore
  File.join(File.dirname(__FILE__), "test_files", klass)
end

def build_config(klass, target=nil, config=nil)
  target = "config.json" unless target
  config_path = File.join(test_files_path(klass), target)
  config = good_config(klass) unless config
  config_string = JSON.pretty_generate(config)
  file = File.open(config_path, "w")
  file.write(config_string)
  file.close
  config_path
end

def good_config(klass)
  root_dir = test_files_path(klass)
  {
    devices: {
      default: :roku,
      roku: {
        ip: "192.168.1.127",
        user: "rokudev",
        password: "aaaa"
      }
    },
    projects: {
      default: :project1,
      project1: {
        directory: root_dir,
        folders: ["resources","source"],
        files: ["manifest"],
        app_name: "<app name>",
        stage_method: :script,
        stages:{
          production: {
            script: {stage: "touch file.tmp", unstage: "rm file.tmp"},
            key: "a"
          }
        }
      }
    },
    keys: {
      a: {
        keyed_pkg: File.join(root_dir, "test.pkg"),
        password: "CvOqcutO3X419INdUbOyqw=="
      }
    },
    input_mappings: {
      "a": ["home", "Home"]
    }
  }
end
