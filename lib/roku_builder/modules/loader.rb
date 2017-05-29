# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder

  # Load/Unload/Build roku applications
  class Loader < Util

    # Sideload an app onto a roku device
    # @param root_dir [String] Path to the root directory of the roku app
    # @param content [Hash] Hash containing arrays for folder, files, and excludes. Default: nil
    # @return [String] Build version on success, nil otherwise
    def sideload(update_manifest: false, content: nil, infile: nil, out_file: nil)
      Navigator.new(config: @config).nav(commands: [:home])
      build_version = nil
      out = out_file
      if infile
        build_version = Manifest.new(config: @config).build_version
        out = infile
      else
        # Update manifest
        manifest = Manifest.new(config: @config)
        if update_manifest
          manifest.increment_build_version
        end
        build_version = manifest.build_version
        @logger.info "Build: #{out}" if out
        out = build(build_version: build_version, out_file: out, content: content)
      end
      path = "/plugin_install"
      # Connect to roku and upload file
      conn = multipart_connection
      payload =  {
        mysubmit: "Replace",
        archive: Faraday::UploadIO.new(out, 'application/zip')
      }
      response = conn.post path, payload
      # Cleanup
      File.delete(out) if infile.nil? and out_file.nil?
      if response.status==200 and response.body=~/Identical to previous version/
        @logger.warn("Sideload identival to previous version")
      elsif not (response.status==200 and response.body=~/Install Success/)
        raise ExecutionError, "Failed Sideloading"
      end
      build_version
    end


    # Build an app to sideload later
    # @param root_dir [String] Path to the root directory of the roku app
    # @param build_version [String] Version to assigne to the build. If nil will pull the build version form the manifest. Default: nil
    # @param out_file [String] Path for the output file. If nil will create a file in /tmp. Default: nil
    # @param content [Hash] Hash containing arrays for folder, files, and excludes. Default: nil
    # @return [String] Path of the build
    def build(build_version: nil, out_file: nil, content: nil)
      content ||= {}
      content[:folders] ||= Dir.entries(@config.parsed[:root_dir]).select {|entry| File.directory? File.join(@config.parsed[:root_dir], entry) and !(entry =='.' || entry == '..') }
      content[:files] ||= Dir.entries(@config.parsed[:root_dir]).select {|entry| File.file? File.join(@config.parsed[:root_dir], entry)}
      content[:excludes] ||= []
      out_file = "#{Dir.tmpdir}/#{build_version}" unless out_file
      out_file = out_file+".zip" unless out_file.end_with?(".zip")
      File.delete(out_file) if File.exist?(out_file)
      io = Zip::File.open(out_file, Zip::File::CREATE)
      # Add folders to zip
      content[:folders].each do |folder|
        base_folder = File.join(@config.parsed[:root_dir], folder)
        if File.exist?(base_folder)
          entries = Dir.entries(base_folder)
          entries.delete(".")
          entries.delete("..")
          writeEntries(@config.parsed[:root_dir], entries, folder, content[:excludes], io)
        else
          @logger.warn "Missing Folder: #{base_folder}"
        end
      end
      # Add file to zip
      writeEntries(@config.parsed[:root_dir], content[:files], "", content[:excludes], io)
      io.close()
      out_file
    end

    # Remove the currently sideloaded app
    def unload()
      path = "/plugin_install"

      # Connect to roku and upload file
      conn = multipart_connection
      payload =  {
        mysubmit: "Delete",
        archive: ""
      }
      response = conn.post path, payload
      unless response.status == 200 and response.body =~ /Install Success/
        raise ExecutionError, "Failed Unloading"
      end
    end

    private

    # Recursively write directory contents to a zip archive
    # @param root_dir [String] Path of the root directory
    # @param entries [Array<String>] Array of file paths of files/directories to store in the zip archive
    # @param path [String] The path of the current directory starting at the root directory
    # @param io [IO] zip IO object
    def writeEntries(root_dir, entries, path, excludes, io)
      entries.each { |e|
        zipFilePath = path == "" ? e : File.join(path, e)
        diskFilePath = File.join(root_dir, zipFilePath)
        if File.directory?(diskFilePath)
          io.mkdir(zipFilePath)
          subdir =Dir.entries(diskFilePath); subdir.delete("."); subdir.delete("..")
          writeEntries(root_dir, subdir, zipFilePath, excludes, io)
        else
          unless excludes.include?(zipFilePath)
            if File.exist?(diskFilePath)
              io.get_output_stream(zipFilePath) { |f| f.puts(File.open(diskFilePath, "rb").read()) }
            else
              @logger.warn "Missing File: #{diskFilePath}"
            end
          end
        end
      }
    end
  end
end
