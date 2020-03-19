require "admiral"
require "../docker/client"
require "../docker/cluster"

module Swm
  module SwmCommand
    @docker_client : DockerClient?
    @cluster : Cluster?

    macro rescue_from_errors
      rescue_from ::Admiral::Error, synopsis
    end

    def synopsis(e)
      puts e.message.colorize(:red)
      puts
      puts help
    end

    def docker_client
      @docker_client ||= DockerClient.new docker_host
    end

    def docker_host : String
      ((ssh_host = arguments.get(:ssh_host)) && "ssh://#{ssh_host}") ||
      presence(ENV.fetch("DOCKER_HOST", nil)) ||
      raise ArgumentError.new("missing DOCKER_HOST")
    end

    def cluster : Cluster
      @cluster ||= Cluster.find(cluster_id) || raise ArgumentError.new("Cluster #{cluster_id} is unknown!")
    end

    def cluster_id : String
      arguments.get(:cluster_id) || begin
        if arguments.get(:ssh_host)
          docker_client.exec("info -f '{{.Swarm.Cluster.ID}}'")
        else
          presence(ENV.fetch("SWM_CLUSTER_ID", nil)) || raise ArgumentError.new("cannot get cluster id")
        end
      end
    end

    def info(message)
      STDERR.puts message
    end

    private def presence(string : String?) : String?
      string unless string.nil? || string.not_nil!.blank?
    end
  end
end
