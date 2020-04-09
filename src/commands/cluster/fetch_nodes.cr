require "../swm_command"

module Swm
  class FetchNodes < Admiral::Command
    include SwmCommand

    define_help description: "update list of swarm nodes from cluster"
    define_argument :ssh_host,
      description: "node to fetch information from (user@host)"
    define_flag use_local_ips : Bool,
      description: "use local ips instead of trying to determine public ips",
      default: false,
      long: "use-local-ips"

    def run
      @cluster = Cluster.load_or_initialize(cluster_id, docker_client)
      info "Updating node list for cluster #{cluster.to_s} via #{docker_client.host}.."
      cluster.fetch_nodes(docker_client)
      puts cluster.to_h
    end
  end
end
