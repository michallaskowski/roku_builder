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
        raf_inspector = RafInspector.new(config: @config, dir: dir)
        manifest_inspector = ManifestInspector.new(config: @config, dir: dir, raf: raf_inspector)
        warnings.concat(manifest_inspector.run(analyzer_config[:inspectors]))
        line_inspector = LineInspector.new(config: @config, dir: dir, raf: raf_inspector)
        warnings.concat(line_inspector.run(analyzer_config[:lineInspectors]))
        warnings.concat(raf_inspector.run(analyzer_config[:inspectors]))
      end
      warnings
    end

    private

    def get_analyzer_config
      #url = "http://devtools.web.roku.com/static-code-analyzer/config.json"
      #url = @options[:analyze_config] if @options[:analyze_config]
      #JSON.parse(Faraday.get(url).body, {symbolize_names: true})
      file = File.join(File.dirname(__FILE__), "inspector_config.json")
      JSON.parse(File.open(file).read, {symbolize_names: true})
    end
  end
  RokuBuilder.register_plugin(Analyzer)


  class LineInspector
    def initialize(config:, dir:, raf:)
      @config = config
      @dir = dir
      @raf_inspector = raf
    end

    def run(inspector_config)
      @warnings = []
      Dir.glob(File.join(@dir, "**", "*")).each do |file_path|
        if File.file?(file_path) and file_path.end_with?(".brs", ".xml")
          File.open(file_path) do |file|
            line_number = 0
            in_xml_comment = false
            file.readlines.each do |line|
              line = line.partition("'").first if file_path.end_with?(".brs")
              if file_path.end_with?(".xml")
                if in_xml_comment
                  if line.gsub!(/.*-->/, "")
                    in_xml_comment = false
                  else
                    line = ""
                  end
                end
                line.gsub!(/<!--.*-->/, "")
                in_xml_comment = true if line.gsub!(/<!--.*/, "")
              end
              inspector_config.each do |line_inspector|
                if /#{line_inspector[:regex]}/.match(line)
                  add_warning(inspector: line_inspector, file: file_path, line: line_number)
                end
              end
              @raf_inspector.inspect_line(line: line, file: file_path, line_number: line_number)
              line_number += 1
            end
          end
        end
      end
      @warnings
    end

    private

    def add_warning(inspector:,  file:, line:)
      @warnings.push(inspector.deep_dup)
      @warnings.last[:path] = file
      @warnings.last[:line] = line
    end
  end

  class ManifestInspector
    def initialize(config:, dir:, raf:)
      @config = config
      @dir = dir
      @raf_inspector = raf
    end

    def run(inspector_config)
      @warnings = []
      @attributes = {}
      @line_numbers = {}
      @inspector_config = inspector_config
      File.open(File.join(@config.root_dir, "manifest")) do |file|
        current_line = 0
        file.readlines.each do |line|
          current_line += 1
          parts = line.split("=")
          key = parts.shift.to_sym
          if @attributes[key]
            add_warning(warning: :manifestDuplicateAttribute, key: key, line: current_line)
          else
            value = parts.join("=").chomp
            if !value or value == ""
              add_warning(warning: :manifestEmptyValue, key: key, line: current_line)
            else
              @attributes[key] = value
              @line_numbers[key] = current_line
            end
          end
        end
      end
      manifest_attributes.each_pair do |key, attribute_config|
        if @attributes[key]
          if attribute_config[:deprecated]
            add_warning(warning: :manifestDeprecatedAttribute, key: key)
          end
          if attribute_config[:validations]
            attribute_config[:validations].each_pair do |type, value|
              case type
              when :integer
                unless @attributes[key].to_i.to_s == @attributes[key]
                  add_warning(warning: :manifestInvalidValue, key: key)
                end
              when :float
                unless @attributes[key].to_f.to_s == @attributes[key]
                  add_warning(warning: :manifestInvalidValue, key: key)
                end
              when :non_negative
                unless @attributes[key].to_f >= 0
                  add_warning(warning: :manifestInvalidValue, key: key)
                end
              when :not_equal
                if value.include? @attributes[key]
                  add_warning(warning: :manifestInvalidValue, key: key)
                end
              when :equals
                unless value.include? @attributes[key]
                  add_warning(warning: :manifestInvalidValue, key: key)
                end
              when :starts_with
                unless @attributes[key].start_with? value
                  add_warning(warning: :manifestInvalidValue, key: key)
                end
              else
                raise ImplementationError, "Unknown Validation"
              end
            end
          end
          if attribute_config[:notify]
            attribute_config[:notify].each do |regexp|
              if /#{regexp}/ =~ @attributes[key]
                add_warning(warning: :manifestHasValue, key: key)
                break
              end
            end
          end
          if attribute_config[:isResource]
            path = File.join(@dir, @attributes[key].gsub("pkg:/", ""))
            unless File.exist?(path)
              mapping = {"{0}": @attributes[key], "{1}": key }
              add_warning(warning: :manifestMissingFile, key: key, mapping: mapping)
            else
              if attribute_config[:resolution]
                size = ImageSize.path(path).size
                target = ImageSize::Size.new(attribute_config[:resolution])
                unless size == target
                  mapping = {
                    "{0}": @attributes[key],
                    "{1}": key,
                    "{2}": size,
                    "{3}": target
                  }
                  add_warning(warning: :manifestIncorrectImageResolution, key: key, mapping: mapping)
                end
              end
            end
          end
        elsif attribute_config[:required]
          add_warning(warning: :manifestMissingAttribute, key: key)
        end
        @raf_inspector.inspect_manifest(attributes: @attributes, line_numbers: @line_numbers)
      end
      @warnings
    end

    private

    def manifest_attributes
      file = File.join(File.dirname(__FILE__), "manifest_attributes.json")
      JSON.parse(File.open(file).read, {symbolize_names: true})
    end
    def add_warning(warning:, key:, mapping: nil, line: nil)
      @warnings.push(@inspector_config[warning].deep_dup)
      @warnings.last[:path] = "manifest"
      if line
        @warnings.last[:line] = line
      elsif @line_numbers[key]
        @warnings.last[:line] = @line_numbers[key]
      end
      if mapping
        mapping.each_pair do |map, value|
          @warnings.last[:message].gsub!(map.to_s, value.to_s)
        end
      else
        @warnings.last[:message].gsub!("{0}", key.to_s)
        if @attributes[key]
          @warnings.last[:message].gsub!("{1}", @attributes[key])
        end
      end
    end
  end

  class RafInspector
    RAF_INTERFACE_INITIALIZATION_PATTERN = /roku_ads\(\)/
    LIBRARY_IMPORT_PATTERN = /\s*library\s*"roku_ads.brs"\s*/

    def initialize(config:, dir:)
      @config = config
      @dir = dir
      @has_raf_interface_initialization = false
      @interface_location = {}
      @has_library_import = false
      @import_location = {}
      @has_manifest_entry = false
      @manifest_location = {path: "manifest"}
    end

    def inspect_line(line:, file:, line_number:)
      unless @has_raf_interface_initialization
        @has_raf_interface_initialization = !!RAF_INTERFACE_INITIALIZATION_PATTERN.match(line)
        if @has_raf_interface_initialization
          @interface_location = {path: file, line: line_number}
        end
      end
      unless @has_library_import
        @has_library_import = !!LIBRARY_IMPORT_PATTERN.match(line)
        if @has_library_import
          @import_location = {path: file, line: line_number}
        end
      end
    end

    def inspect_manifest(attributes:, line_numbers:)
      if attributes[:bs_libs_required] and attributes[:bs_libs_required].downcase == "roku_ads_lib"
        @has_manifest_entry = true
        @manifest_location[:line] = line_numbers[:bs_libs_required]
      end
    end

    def run(inspector_config)
      @warnings = []
      @inspector_config = inspector_config
      if @has_raf_interface_initialization and !@has_library_import
        add_warning(warning: :rafConstructorPresentImportMissing, location: @interface_location)
      end
      if @has_raf_interface_initialization and !@has_manifest_entry
        add_warning(warning: :rafConstructorPresentManifestMissing, location: @interface_location)
      end
      if !@has_raf_interface_initialization and @has_manifest_entry
        add_warning(warning: :rafConstructorMissingManifestPresent, location: @manifest_location)
      end
      if @has_manifest_entry and !@has_library_import
        add_warning(warning: :rafManifestPresentImportMissing, location: @manifest_location)
      end
      if !@has_raf_interface_initialization and @has_library_import
        add_warning(warning: :rafConstructorMissingImportPresent, location: @import_location)
      end
      if @has_raf_interface_initialization and @has_library_import and @has_manifest_entry
        add_warning(warning: :rafProperIntegration, location: @import_location)
      end
      @warnings
    end

    private

    def add_warning(warning:, location:)
      @warnings.push(@inspector_config[warning].deep_dup)
      @warnings.last[:path] = location[:path]
      @warnings.last[:line] = location[:line]
    end
  end
end

