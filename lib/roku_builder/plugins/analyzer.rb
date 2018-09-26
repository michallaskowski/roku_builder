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

    def analyze(options:, quiet: false)
      @options = options
      @warnings = []
      analyzer_config = get_analyzer_config
      @inspector_config = analyzer_config[:inspectors]
      loader = Loader.new(config: @config)
      Dir.mktmpdir do |dir|
        loader.copy(options: options, path: dir)
        raf_inspector = RafInspector.new(config: @config, dir: dir)
        manifest_inspector = ManifestInspector.new(config: @config, dir: dir, raf: raf_inspector)
        @warnings.concat(manifest_inspector.run(analyzer_config[:inspectors]))
        has_source_dir = false
        Dir.glob(File.join(dir, "**", "*")).each do |file_path|
          if File.file?(file_path) and file_path.end_with?(".brs", ".xml")
            line_inspector = LineInspector.new(config: @config, raf: raf_inspector, inspector_config: analyzer_config[:lineInspectors])
            @warnings.concat(line_inspector.run(file_path))
          end
          if file_path.end_with?("__MACOSX")
            add_warning(warning: :packageMacosxDirectory, path: file_path)
          end
          if file_path.end_with?(".zip", ".md", ".pkg")
            add_warning(warning: :packageExtraneousFiles, path: file_path)
          end
          has_source_dir  = true if file_path.end_with?("source")
        end
        unless has_source_dir
          add_warning(warning: :packageSourceDirectory, path: "source")
        end
        @warnings.concat(raf_inspector.run(analyzer_config[:inspectors]))
        print_warnings(dir) unless quiet
      end
      @warnings
    end

    private

    def get_analyzer_config
      #url = "http://devtools.web.roku.com/static-code-analyzer/config.json"
      #url = @options[:analyze_config] if @options[:analyze_config]
      #JSON.parse(Faraday.get(url).body, {symbolize_names: true})
      file = File.join(File.dirname(__FILE__), "inspector_config.json")
      JSON.parse(File.open(file).read, {symbolize_names: true})
    end

    def add_warning(warning:, path:)
      @warnings.push(@inspector_config[warning].deep_dup)
      @warnings.last[:path] = path
    end

    def print_warnings(dir)
      logger = ::Logger.new(STDOUT)
      logger.level  = @logger.level
      logger.formatter = proc {|severity, _datetime, _progname, msg|
        "%5s: %s\n\r" % [severity, msg]
      }
      @warnings.each do |warning|
        message = warning[:message]
        if warning[:path]
          warning[:path].slice!(dir) if dir
          warning[:path].slice!(/^\//)
          message += ". pkg:/"+warning[:path]
          message += ":"+warning[:line].to_s if warning[:line]
        end
        case(warning[:severity])
        when "error"
          logger.error(message)
        when "warning"
          logger.warn(message)
        when "info"
          logger.info(message)
        end
      end
    end
  end
  RokuBuilder.register_plugin(Analyzer)
end

