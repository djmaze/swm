require "../swm_command"

module Swm
  class RemoveCluster < Admiral::Command
    include SwmCommand

    define_help description: "remove cluster from the list"
    define_argument :cluster_id,
      description: "id of cluster to remove"

    def run
      puts "Removing #{cluster.to_s}"
      cluster.rm!
    end
  end
end
