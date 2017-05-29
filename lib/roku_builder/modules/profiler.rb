# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder

  # Scene Graph Profiler
  class Profiler < Util

    # Run the profiler commands
    # @param command [Symbol] The profiler command to run
    def run(command:)
      case command
      when :stats
        print_stats
      end
    end

    private

    # Print the node stats
    def print_stats
      lines = get_all_nodes
      xml_string = lines.join("\n")
      stats = {"Total" => 0}
      doc = Nokogiri::XML(xml_string)
      handle_node(stats: stats, node: doc.root)
      stats = stats.to_a
      stats = stats.sort {|a, b| b[1] <=> a[1]}
      printf "%30s | %5s\n", "Name", "Count"
      stats.each do |key_pair|
        printf "%30s | %5d\n", key_pair[0], key_pair[1]
      end
    end

    def handle_node(stats:,  node:)
      node.element_children.each do |element|
        stats[element.name] ||= 0
        stats[element.name] += 1
        stats["Total"] += 1
        handle_node(stats: stats, node: element)
      end
    end

    # Retrive list of all nodes
    # @return [Array<String>] Array of lines
    def get_all_nodes
      waitfor_config = {
        'Match' => /.+/,
        'Timeout' => 5
      }
      telnet_config ={
        'Host' => @roku_ip_address,
        'Port' => 8080
      }

      connection = Net::Telnet.new(telnet_config)

      lines = []
      all_txt = ""
      in_nodes = false
      done = false
      connection.puts("sgnodes all\n")
      while not done
        begin
          connection.waitfor(waitfor_config) do |txt|
            in_nodes, done, all_txt = handle_text(all_txt: all_txt, txt: txt, in_nodes: in_nodes, lines: lines)
          end
        rescue Net::ReadTimeout
          @logger.warn "Timed out reading profiler information"
          done = true
        end
      end
      lines
    end

    # Handle profiling text
    # @param all_txt [String] remainder text from last run
    # @param txt [String] current text from telnet
    # @param in_nodes [Boolean] currently parsing test text
    # @return [Boolean] currently parsing test text
    def handle_text(all_txt:, txt:, in_nodes:, lines:)
      all_txt += txt
      end_reg = /<\/All_Nodes>/
      start_reg = /<All_Nodes>/
      done = false
      while line = all_txt.slice!(/^.*\n/) do
        in_nodes = true if line =~ start_reg
        lines.push(line) if in_nodes
        if line =~ end_reg
          in_nodes = false
          done = true
        end
      end
      [in_nodes, done, all_txt]
    end
  end
end
