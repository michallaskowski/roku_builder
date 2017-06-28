# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder

  # Scene Graph Profiler
  class Profiler < Util
    extend Plugin

    def self.commands
      {profile: {device: true}}
    end

    def self.parse_options(parser:, options:)
      parser.separator "Commands:"
      parser.on("--profile COMMAND", "Run various profiler options") do |c|
        options[:profile] = c
      end
    end

    # Run the profiler commands
    # @param command [Symbol] The profiler command to run
    def profile(options:)
      case options[:profile].to_sym
      when :stats
        print_stats
      when :all
        print_all_nodes
      when :images
        print_image_information
      when :textures
        print_texture_information
      end
    end

    private

    # Print the node stats
    def print_stats
      end_reg = /<\/All_Nodes>/
      start_reg = /<All_Nodes>/
      lines = get_command_response(command: "sgnodes all", start_reg: start_reg, end_reg: end_reg)
      xml_string = lines.join("\n")
      stats = {"Total" => 0}
      doc = Oga.parse_xml(xml_string)
      handle_node(stats: stats, node: doc.children.first)
      stats = stats.to_a
      stats = stats.sort {|a, b| b[1] <=> a[1]}
      printf "%30s | %5s\n", "Name", "Count"
      stats.each do |key_pair|
        printf "%30s | %5d\n", key_pair[0], key_pair[1]
      end
    end

    def handle_node(stats:,  node:)
      node.children.each do |element|
        next unless element.class == Oga::XML::Element
        stats[element.name] ||= 0
        stats[element.name] += 1
        stats["Total"] += 1
        handle_node(stats: stats, node: element)
      end
    end

    def print_all_nodes
      start_reg = /<All_Nodes>/
      end_reg = /<\/All_Nodes>/
      lines = get_command_response(command: "sgnodes all", start_reg: start_reg, end_reg: end_reg)
      lines.each {|line| print line}
    end
    def print_image_information
      start_reg = /RoGraphics instance/
      end_reg = /Available memory/
      lines = get_command_response(command: "r2d2_bitmaps", start_reg: start_reg, end_reg: end_reg)
      lines.each {|line| print line}
    end
    def print_texture_information
      start_reg = /\*+/
      end_reg = /#{SecureRandom.uuid}/
      lines = get_command_response(command: "loaded_textures", start_reg: start_reg, end_reg: end_reg)
      lines.each {|line| print line}
    end

    # Retrive list of all nodes
    # @return [Array<String>] Array of lines
    def get_command_response(command:, start_reg:, end_reg:, unique: false)
      waitfor_config = {
        'Match' => /.+/,
        'Timeout' => 5
      }
      telnet_config ={
        'Host' => @roku_ip_address,
        'Port' => 8080
      }

      connection = Net::Telnet.new(telnet_config)

      @lines = []
      @all_txt = ""
      @begun = false
      @done = false
      connection.puts("#{command}\n")
      while not @done
        begin
          connection.waitfor(waitfor_config) do |txt|
            handle_text(txt: txt, start_reg: start_reg, end_reg: end_reg, unique: unique)
          end
        rescue Net::ReadTimeout
          @logger.warn "Timed out reading profiler information"
          @done = true
        end
      end
      @lines
    end

    # Handle profiling text
    # @param all_txt [String] remainder text from last run
    # @param txt [String] current text from telnet
    # @param in_nodes [Boolean] currently parsing test text
    # @return [Boolean] currently parsing test text
    def handle_text(txt:, start_reg:, end_reg:, unique:)
      @all_txt += txt
      while line = @all_txt.slice!(/^.*\n/) do
        if line =~ start_reg
          @begun = true
          @lines = [] if unique
        end
        @lines.push(line) if @begun
        if line =~ end_reg
          @begun = false
          @done = true
        end
      end
    end
  end
  RokuBuilder.register_plugin(Profiler)
end
