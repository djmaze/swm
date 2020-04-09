require "./container"

module Swm
  class Service
    getter name : String

    def self.create(name : String, cluster : Cluster, image : String, options : String, command : String, client : DockerClient?)
      client ||= DockerClient.for_cluster(cluster)
      client.exec "service create --name #{name} #{options} #{image} #{command}"
      new name, cluster, client
    end

    def initialize(@name : String, @cluster : Cluster, @client : DockerClient? = nil)
    end

    def containers : Array(Container)
      client.exec("service ps -f desired-state=running --format '{{.Node}} {{.ID}} {{.DesiredState}} {{.CurrentState}}' #{@name} | grep 'Running Running' | awk '{print $1 \" \" $2}'")
      .split("\n")
      .map do |line|
        raise ArgumentError.new("Service \"#{@name}\" does not exist") if line.strip.blank?
        node_name, task = line.split
        id = client.exec("inspect -f '{{.Status.ContainerStatus.ContainerID}}' #{task}")
        node = @cluster.find_node(node_name)
        if node
          Container.new node: node, task: task, id: id
        else
          raise "Node #{node_name} not found"
        end
      end
    end

    def follow
      if complete?
        STDERR.puts "Task for service #{name} already finished. Log output:"
        STDOUT.puts client.exec("service logs #{name}")
      else
        client.exec_async "service logs -f #{name}", show_output: true do
          wait_for_completion
        end
        STDERR.puts "Task for service #{name} finished."
      end
    end

    def rm!
      client.exec "service rm #{name}"
    end

    def get_last_output_line
      wait_for_completion
      client.exec("service logs --tail 1 --no-task-ids #{name} | awk -F '@' '{print $2}' | awk -F '|' '{print $1 \" \" $2}'").split("\n")
    end

    def wait_for_completion
      client.wait_for { complete? }
    end

    def complete?
      check_service_state "Complete"
    end

    def check_service_state(state) : Bool
      client.exec("service ps --format '{{.CurrentState}}' #{name} | grep -v #{state} || true").blank?
    end

    private def client : DockerClient
      @client ||= DockerClient.for_cluster(@cluster)
    end
  end
end
