# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder

  # Change or get dev key
  class Keyer < Util

    def genkey(out_file: nil)
      password, dev_id = generate_new_key()
      @logger.unknown("Password: "+password)
      @logger.info("DevID: "+dev_id)

      unless out_file
        out_file = File.join(Dir.tmpdir, "key_"+dev_id+".pkg")
      end

      Dir.mktmpdir { |dir|
        config_copy = @config.dup
        config_copy.root_dir = dir
        Manifest.generate({config: @config, attributes: {}})
        Dir.mkdir(File.join(dir, "source"))
        File.open(File.join(dir, "source", "main.brs"), "w") do |io|
          io.puts "sub main()"
          io.puts "  print \"Load\""
          io.puts "end sub"
        end
        loader = Loader.new(config: @config)
        loader.sideload()
        packager = Packager.new(config: @config)
        packager.package(app_name_version: "key_"+dev_id, out_file: out_file, password: password)
        @logger.unknown("Keyed PKG: "+out_file)
      }
    end

    # Sets the key on the roku device
    # @param keyed_pkg [String] Path for a package signed with the desired key
    # @param password [String] Password for the package
    # @return [Boolean] True if key changed, false otherwise
    def rekey(keyed_pkg:, password:)
      oldId = dev_id

      # upload new key with password
      path = "/plugin_inspect"
      conn = multipart_connection
      payload =  {
        mysubmit: "Rekey",
        passwd: password,
        archive: Faraday::UploadIO.new(keyed_pkg, 'application/octet-stream')
      }
      conn.post path, payload

      # check key
      newId = dev_id
      @logger.info("Key did not change") unless newId != oldId
      @logger.debug(oldId + " -> " + newId)
      newId != oldId
    end

    # Get the current dev id
    # @return [String] The current dev id
    def dev_id
      path = "/plugin_package"
      conn = simple_connection
      response = conn.get path

      dev_id = /Your Dev ID:\s*<font[^>]*>([^<]*)<\/font>/.match(response.body)
      dev_id ||= /Your Dev ID:[^>]*<\/label> ([^<]*)/.match(response.body)
      dev_id = dev_id[1] if dev_id
      dev_id ||= "none"
      dev_id
    end

    private

    # Uses the device to generate a new signing key
    #  @return [Array<String>] Password and dev_id for the new key
    def generate_new_key()
      telnet_config = {
        'Host' => @roku_ip_address,
        'Port' => 8080
      }
      connection = Net::Telnet.new(telnet_config)
      connection.puts("genkey")
      waitfor_config = {
        'Match' => /./,
        'Timeout' => false
      }
      password = nil
      dev_id = nil
      while password.nil? or dev_id.nil?
        connection.waitfor(waitfor_config) do |txt|
          while line = txt.slice!(/^.*\n/) do
            words = line.split
            if words[0] == "Password:"
              password = words[1]
            elsif words[0] == "DevID:"
              dev_id = words[1]
            end
          end
        end
      end
      connection.close
      return password, dev_id
    end
  end
end
