# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder

  # Commands that the controller uses to interface with the rest of the gem.
  class ControllerCommands

    # Run Package
    # @param options [Hash] user options
    # @param config [Conifg] config object
    # @return [Integer] Success or Failure Code
    def self.package(options:, config:)
      loader_config = config.parsed[:device_config].dup
      loader_config[:init_params] = config.parsed[:init_params][:loader]
      keyer = Keyer.new(**config.parsed[:device_config])
      stager = Stager.new(**config.parsed[:stage_config])
      loader = Loader.new(**loader_config)
      packager = Packager.new(**config.parsed[:device_config])
      Logger.instance.warn "Packaging working directory" if options[:working]
      if stager.stage
        # Sideload #
        code, build_version = loader.sideload(**config.parsed[:sideload_config])
        return code unless code == SUCCESS
        # Key #
        _success = keyer.rekey(**config.parsed[:key])
        # Package #
        options[:build_version] = build_version
        config.update
        success = packager.package(**config.parsed[:package_config])
        Logger.instance.info "Signing Successful: #{config.parsed[:package_config][:out_file]}" if success
        return FAILED_SIGNING unless success
        # Inspect #
        if options[:inspect]
          inspect_package(config: config)
        end
      end
      stager.unstage
      Logger.instance.info "App Packaged; staged using #{stager.method}"
      SUCCESS
    end
    # Run update
    # @param config [Config] config object
    # @return [Integer] Success or Failure Code
    def self.update(config:)
      ### Update ###
      stager = Stager.new(**config.parsed[:stage_config])
      if stager.stage
        manifest = Manifest.new(config: config)
        old_version = manifest.build_version
        manifest.increment_build_version
        new_version = manifest.build_version
        Logger.instance.info "Update build version from:\n#{old_version}\nto:\n#{new_version}"
      end
      stager.unstage
      SUCCESS
    end
  end
end
