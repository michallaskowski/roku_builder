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

RokuBuilder::Logger.set_testing

def test_files_path(klass)
  klass = klass.to_s.split("::")[1].underscore
  File.join(File.dirname(__FILE__), "test_files", klass)
end

def build_options(options = {screens: true})
  RokuBuilder::Options.new(options: options)
end

def good_config
  {
    devices: {
    default: :roku,
    roku: {
    ip: "192.168.0.100",
    user: "user",
    password: "password"
  }
  },
    projects: {
    default: :project1,
    project1: {
    directory: "/tmp",
    folders: ["resources","source"],
    files: ["manifest"],
    app_name: "<app name>",
    stage_method: :git,
    stages:{
    production: {
    branch: "production",
    key: {
    keyed_pkg: "/tmp",
    password: "<password for pkg>"
  }
  }
  }
  },
    project2: {
    directory: "/tmp",
    folders: ["resources","source"],
    files: ["manifest"],
    app_name: "<app name>",
    stage_method: :git,
    stages:{
    production: {
    branch: "production",
    key: "a"
  }
  }
  }
  },
    keys: {
    a: {
    keyed_pkg: "/tmp",
    password: "password"
  }
  },
    input_mapping: {
    "a": ["home", "Home"]
  }
  }
end
