require "../swm_command"

module Swm
  class ListClusters < Admiral::Command
    include SwmCommand

    define_help description: "list all configured swarm clusters"

    def run
      puts(
        Cluster
        .all
        .map(&.to_h)
        .join("\n\n")
      )
    end
  end
end
