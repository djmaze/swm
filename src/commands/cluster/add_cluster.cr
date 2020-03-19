require "../swm_command"
#require "./cluster/*"

module Swm
  class AddCluster < Admiral::Command
    include SwmCommand

    rescue_from_errors

    define_help description: "add new cluster and fetch nodes from manager node"
    define_argument :name,
      description: "name for the cluster",
      required: true
    define_argument :ssh_host,
      description: "node to fetch information from (user@host)",
      required: true
    define_flag use_local_ips : Bool,
      description: "use local ips instead of trying to determine public ips",
      default: false,
      long: "use-local-ips"

    def run
      raise ArgumentError.new("Cluster with name #{arguments.name} already exists!") if Cluster.find(arguments.name)

      @cluster = Cluster.new(arguments.name, docker_client, flags.use_local_ips)
      info "Fetching nodes for new cluster #{@cluster.to_s} via #{docker_client.host}.."
      cluster.fetch_nodes(docker_client)
      info cluster.to_h
    end
  end
end
