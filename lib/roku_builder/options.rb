# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder
  class Options < Hash
    def initialize(options: nil)
      @logger = Logger.instance
      options ||= parse
      merge!(options)
    end

    def validate
      validate_commands
      validate_sources
      validate_combinations
      validate_deprivated
    end

    def command
      (keys & commands).first
    end

    def exclude_command?
      exclude_commands.include?(command)
    end

    def source_command?
      (source_commands & keys).count > 0
    end

    def device_command?
      device_commands.include?(command)
    end

    def has_source?
      !(keys & sources).empty?
    end

    private

    def parse
      options = {}
      options[:config] = '~/.roku_config.json'
      options[:update_manifest] = false
      parser = build_parser(options: options)
      validate_parser(parser: parser)
      begin
        parser.parse!
      rescue StandardError => e
        @logger.fatal e.message
        exit
      end
      options
    end

    def build_parser(options:)
      OptionParser.new do |opts|
        opts.banner = "Usage: roku <command> [options]"
        opts.separator "Core Comamnads:"
        opts.on("--configure", "Command: Copy base configuration file to the --config location. Default: '~/.roku_config.json'") do
          options[:configure] = true
        end
        opts.on("--validate", "Command: Validate configuration'") do
          options[:validate] = true
        end
        opts.on("--do-stage", "Command: Run the stager. Used for scripting. Always run --do-unstage after") do
          options[:dostage] = true
        end
        opts.on("--do-unstage", "Command: Run the unstager. Used for scripting. Always run --do-script first") do
          options[:dounstage] = true
        end
        opts.separator ""
        opts.separator "Config Options:"
        opts.on("-e", "--edit PARAMS", "Edit config params when configuring. (eg. a:b, c:d,e:f)") do |p|
          options[:edit_params] = p
        end
        opts.on("--config CONFIG", "Set a custom config file. Default: '~/.roku_config.json'") do |c|
          options[:config] = c
        end
        opts.separator ""
        opts.separator "Source Options:"
        opts.on("-r", "--ref REF", "Git referance to use for sideloading") do |r|
          options[:ref] = r
        end
        opts.on("-w", "--working", "Use working directory to sideload or test") do
          options[:working] = true
        end
        opts.on("-c", "--current", "Use current directory to sideload or test. Overrides any project config") do
          options[:current] = true
        end
        opts.on("-s", "--stage STAGE", "Set the stage to use. Default: 'production'") do |b|
          options[:stage] = b
          options[:set_stage] = true
        end
        opts.on("-P", "--project ID", "Use a different project") do |p|
          options[:project] = p
        end
        opts.separator ""
        opts.separator "Other Options:"
        opts.on("-D", "--device ID", "Use a different device corresponding to the given ID") do |d|
          options[:device] = d
          options[:device_given] = true
        end
        opts.on("-V", "--verbose", "Print Info message") do
          options[:verbose] = true
        end
        opts.on("--debug", "Print Debug messages") do
          options[:debug] = true
        end
        opts.on("-h", "--help", "Show this message") do
          puts opts
          exit
        end
        opts.on("-v", "--version", "Show version") do
          puts RokuBuilder::VERSION
          exit
        end
      end
    end

    def validate_parser(parser: )
      short = []
      long = []
      stack = parser.instance_variable_get(:@stack)
      stack.each do |optionsList|
        optionsList.each_option do |option|
          if short.include?(option.short)
            raise ImplementationError, "Duplicate option defined: #{option.short}"
          end
          short.push(option.short)
          if long.include?(option.long)
            raise ImplementationError, "Duplicate option defined: #{option.long}"
          end
          long.push(option.long)
        end
      end
    end

    def validate_commands
      all_commands = keys & commands
      raise InvalidOptions, "Only specify one command" if all_commands.count > 1
      raise InvalidOptions, "Specify at least one command" if all_commands.count < 1
    end

    def validate_sources
      all_sources = keys & sources
      raise InvalidOptions, "Only spefify one source" if all_sources.count > 1
      if source_command? and !has_source?
        raise InvalidOptions, "Must specify a source for that command"
      end
    end

    def validate_combinations
      all_sources = keys & sources
      if all_sources.include?(:current) and not (self[:build] or self[:sideload])
        raise InvalidOptions, "Current source onle works for build or sideload"
      end
      if self[:in] and not self[:sideload]
        raise InvalidOptions, "In source only works for sideloading"
      end
    end

    def validate_deprivated
      depricated = keys & depricated_options.keys
      if depricated.count > 0
        depricated.each do |key|
          @logger.warn depricated_options[key]
        end
      end
    end

    # List of command options
    # @return [Array<Symbol>] List of command symbols that can be used in the options hash
    def commands
      [:sideload, :package, :test, :deeplink,:configure, :validate, :delete,
        :navigate, :navigator, :text, :build, :monitor, :update, :screencapture,
        :key, :genkey, :screen, :screens, :applist, :print, :profile, :dostage,
        :dounstage]
    end

    # List of depricated options
    # @return [Hash] Hash of depricated options and the warning message for each
    def depricated_options
      {deeplink_depricated: "-L and --deeplink are depricated. Use -o or --deeplink-options." }
    end

    # List of source options
    # @return [Array<Symbol>] List of source symbols that can be used in the options hash
    def sources
      [:ref, :set_stage, :working, :current, :in]
    end

    # List of commands requiring a source option
    # @return [Array<Symbol>] List of command symbols that require a source in the options hash
    def source_commands
      [:sideload, :package, :test, :build, :key, :update, :print]
    end

    # List of commands the activate the exclude files
    # @return [Array<Symbol] List of commands the will activate the exclude files lists
    def exclude_commands
      [:build, :package]
    end

    # List of commands that require a device
    # @return [Array<Symbol>] List of commands that require a device
    def device_commands
      [:sideload, :package, :test, :deeplink, :delete, :navigate, :navigator,
        :text, :monitor, :screencapture, :applist, :profile, :key, :genkey ]
    end
  end
end
