require "admiral"
require "./commands/*"

module Swm
  VERSION = "0.1.0"

  class Main < Admiral::Command
    define_help description: "The missing tooling for a great Docker swarm experience"

    register_sub_command "cluster", ClusterCommand
    register_sub_command "stack", StackCommand
    register_sub_command "service", ServiceCommand

    def run
      if arguments.any? && arguments[0] == "swm" && arguments.size > 1
        if arguments.size > 1
          return sub(arguments[1], arguments[2..-1])
        else
          return sub(arguments[1])
        end
      elsif arguments.size > 0 && arguments[0] == "docker-cli-plugin-metadata"
        # Special handling in order to hide from help
        CliPluginMetadata.new.run
      else
        puts help
      end
    rescue ex : ArgumentError
      STDERR.puts "Error: #{ex}"
      exit 1
    end
  end
end

Swm::Main.run
