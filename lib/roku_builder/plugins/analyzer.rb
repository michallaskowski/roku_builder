# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder

  # Collects information on a package for submission
  class Analyzer < Util
    extend Plugin

    def self.commands
      {
        analyze: {source: true},
      }
    end

    def self.parse_options(parser:, options:)
      parser.separator "Commands:"
      parser.on("--analyze", "Run a static analysis on a given stage") do
        options[:analyze] = true
      end
    end

    def self.dependencies
      [Loader]
    end

    def analyze(options:)
      @options = options
      warnings = []
      analyzer_config = get_analyzer_config
      loader = Loader.new(config: @config)
      Dir.mktmpdir do |dir|
        loader.copy(options: options, path: dir)
        inspector = ManifestInspector.new(config: @config, dir: dir)
        warnings.concat(inspector.run(analyzer_config[:inspectors]))
      end
      warnings
    end

    private

    def get_analyzer_config
      url = "http://devtools.web.roku.com/static-code-analyzer/config.json"
      url = @options[:analyze_config] if @options[:analyze_config]
      JSON.parse(Faraday.get(url).body, {symbolize_names: true})
    end
  end
  RokuBuilder.register_plugin(Analyzer)

  class ManifestInspector
    def initialize(config:, dir:)
      @config = config
      @dir = dir
    end

    def run(inspector_config)
      @warnings = []
      attributes = {}
      File.open(File.join(@config.root_dir, "manifest")) do |file|
        file.readlines.each do |line|
          parts = line.split("=")
          key = parts.shift.to_sym
          if attributes[key]
            @warnings.push(inspector_config[:manifestDuplicateAttribute].dup)
            @warnings.last[:message].gsub!("{0}", key.to_s)
          else
            value = parts.join("=")
            attributes[key] = value
          end
        end
      end
      manifest_attributes.each_pair do |key, attribute_config|
        if attributes[key]
          if attribute_config[:deprecated]
            @warnings.push(inspector_config[:manifestDeprecatedAttribute].dup)
            @warnings.last[:message].gsub!("{0}", key.to_s)
          end
        end
      end

      @warnings
    end

    private

    def manifest_attributes
      file = File.join(File.dirname(__FILE__), "manifest_attributes.json")
      JSON.parse(File.open(file).read, {symbolize_names: true})
    end
  end
end

