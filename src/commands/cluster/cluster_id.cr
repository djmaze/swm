require "../swm_command"

module Swm
  class ClusterID < Admiral::Command
    include SwmCommand

    define_help description: "return swarm ID of current cluster"

    def run
      puts cluster.id
    end
  end
end
