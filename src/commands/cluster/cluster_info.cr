require "../swm_command"

module Swm
  class ClusterInfo < Admiral::Command
    include SwmCommand

    define_help description: "show cluster information (including list of nodes)"
    define_argument :cluster_id,
      description: "id of swarm cluster (default: $SWM_CLUSTER_ID)"

    def run
      @cluster = Cluster.load(cluster_id)
      puts cluster.to_h
    end
  end
end
