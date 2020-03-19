require "../swm_command"

module Swm
  class GetEnv < Admiral::Command
    include SwmCommand

    define_help description: "get environment variables for a node in the given cluster"
    define_argument :cluster_id,
      description: "cluster id to get environment for"

    def run
      if arguments.cluster_id == "local"
        print_error "Resetting env to localhost"
        puts "export SWM_CLUSTER_ID="
        puts "export DOCKER_HOST="
      else
        node = cluster.random_manager_node
        print_error "Using node #{node.hostname} (#{node.ip})"
        puts "export SWM_CLUSTER_ID=#{cluster.id}"
        puts "export DOCKER_HOST=ssh://#{node.ssh_host}"
      end
    end
  end
end
