require "ssh2"

require "./service"
require "./local_docker_executor"
require "./ssh_docker_executor"

module Swm
  class DockerClient
    @@cluster_nodes = {} of Cluster => Node
    @@clients = {} of Node => DockerClient

    getter host : String

    def self.for_cluster(cluster : Cluster) : DockerClient
      @@cluster_nodes[cluster] ||= cluster.random_manager_node
      DockerClient.for_node(@@cluster_nodes[cluster])
    end

    def self.for_node(node : Node) : DockerClient
      @@clients[node] ||= new("ssh://" + node.ssh_host)
    end

    def initialize(@host : String)
      @local_docker_executor = LocalDockerExecutor.new(@host)
      @ssh_docker_executor = SSHDockerExecutor.new(@host)
    end

    def wait_for(&block)
      while !yield
        sleep 5
      end
    end

    delegate :exec, to: @local_docker_executor
    delegate :exec_async, to: @ssh_docker_executor

    # Due to current Crystal language limitations, 
    # this cannot be delegated
    def watch(command : String, &block)
      @ssh_docker_executor.watch(command, &block)
    end
  end
end
