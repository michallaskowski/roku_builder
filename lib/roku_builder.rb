# ********** Copyright 2016 Viacom, Inc. Apache 2.0 **********

require "logger"
require "faraday"
require "faraday/digestauth"
require "pathname"
require "rubygems"
require "optparse"
require "pathname"
require "net/ping"
#config_manager
require 'json'
#stager
require 'pstore'
require "git"
#profiler
require 'nokogiri'
#navigator
require 'io/console'
#monitor
require 'readline'
#loader
require "net/telnet"
require "fileutils"
require "tempfile"
require "tmpdir"
require "zip"


Dir.glob(File.join(File.dirname(__FILE__), "roku_builder", "*.rb")).each do |path|
  file = "roku_builder/"+File.basename(path, ".rb")
  require file
end
Dir.glob(File.join(File.dirname(__FILE__), "roku_builder", "modules", "*.rb")).each do |path|
  file = "roku_builder/modules/"+File.basename(path, ".rb")
  require file
end

module RokuBuilder
  # Run the builder
  # @param options [Hash] The options hash
  def self.run

    #load modules

    options = Options.new

    initialize_logger(options: options)

    config = load_config(options: options)

    check_devices(options: options, config: config)

    execute_command(options: options, config: config)
  end

  def self.initialize_logger(options:)
    if options[:debug]
      Logger.set_debug
    elsif options[:verbose]
      Logger.set_info
    else
      Logger.set_warn
    end
  end

  def self.load_config(options:)
    config = Config.new(options: options)
    config.configure
    config.load
    config.validate
    config.parse
    config
  end

  def self.check_devices(options:, config:)
    if options.device_command?
      ping = Net::Ping::External.new
      host = config.parsed[:device_config][:ip]
      return if ping.ping? host, 1, 0.2, 1
      raise DeviceError, "Device not online" if options[:device_given]
      config.raw[:devices].each_pair {|key, value|
        unless key == :default
          host = value[:ip]
          if ping.ping? host, 1, 0.2, 1
            config.parsed[:device_config] = value
            Logger.instance.warn("Default device offline, choosing Alternate")
            return
          end
        end
      }
      raise DeviceError, "No devices found"
    end
  end

  def self.execute_command(options:, config:)
  end

  # Parses a string into and options hash
  # @param options [String] string of options in the format "a:b, c:d"
  # @return [Hash] Options hash generated
  def self.options_parse(options:)
    parsed = {}
    opts = options.split(/,\s*/)
    opts.each do |opt|
      opt = opt.split(":")
      key = opt.shift.to_sym
      value = opt.join(":")
      parsed[key] = value
    end
    parsed
  end

  # Run a system command
  # @param command [String] The command to be run
  # @return [String] The output of the command
  def self.system(command:)
    `#{command}`.chomp
  end
end
