# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder

  # Commands that the controller uses to interface with the rest of the gem.
  class ControllerCommands

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
