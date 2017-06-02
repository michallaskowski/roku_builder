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
require "webmock/minitest"


RokuBuilder::Logger.set_testing
WebMock.disable_net_connect!
def register_plugins(plugin_class)
  plugins = [plugin_class]
  plugins.each do |plugin|
    plugins.concat(plugin.dependencies)
    unless RokuBuilder.plugins.include?(plugin)
      RokuBuilder.register_plugin(plugin)
    end
  end
end
def build_config_options_objects(klass, options = {validate: true}, empty_plugins = true)
  options = build_options(options, empty_plugins)
  config = RokuBuilder::Config.new(options: options)
  config.instance_variable_set(:@config, good_config(klass))
  config.parse
  [config, options]
end

def build_config_object(klass, options= {validate: true}, empty_plugins = true)
  build_config_options_objects(klass, options, empty_plugins).first
end

def test_files_path(klass)
  klass = klass.to_s.split("::")[1].underscore
  File.join(File.dirname(__FILE__), "test_files", klass)
end

def build_options(options = {validate: true}, empty_plugins = true)
  RokuBuilder.class_variable_set(:@@plugins, []) if empty_plugins
  options = RokuBuilder::Options.new(options: options)
  options.validate
  options
end

def good_config(klass=nil)
  root_dir = "/tmp"
  root_dir = test_files_path(klass) if klass
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
    directory: root_dir,
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
    directory: root_dir,
    folders: ["resources","source"],
    files: ["manifest"],
    app_name: "<app name>",
    stage_method: :script,
    stages:{
    production: {
    script: {stage: "stage_script", unstage: "unstage_script"},
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
