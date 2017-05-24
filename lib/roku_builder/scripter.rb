# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder

  # Helper for extending for scripting
  class Scripter

    # Prints attributes from config or project to allow scripting
    # @param attribute [Symbol] attribute to print
    # @param configs [Hash] Parsed config hash
    def self.print(attribute:, config:)
      attributes = [
        :title, :build_version, :app_version, :root_dir, :app_name
      ]

      unless attributes.include? attribute
        return BAD_PRINT_ATTRIBUTE
      end

      manifest = Manifest.new(config: config)

      case attribute
      when :root_dir
        printf "%s", config.parsed[:project_config][:directory]
      when :app_name
        printf "%s", config.parsed[:project_config][:app_name]
      when :title
        printf "%s", manifest.title
      when :build_version
        printf "%s", manifest.build_version
      when :app_version
        major = manifest.major_version
        minor = manifest.minor_version
        printf "%s.%s", major, minor
      end
      SUCCESS
    end
  end
end
