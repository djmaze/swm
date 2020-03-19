require "json"
require "./cluster"
require "./node"

module Swm
  class NodeListFetcher
    SERVICE_NAME = "swm-get-ip"

    def self.fetch_with_local_ips(client : DockerClient) : Array(Node)
      new_nodes = [] of Node
      client.exec("node ls --format '{{.Hostname}}'").split("\n").each do |name|
        role, ip, user = client.exec("node inspect -f '{{.Spec.Role}}|{{.Status.Addr}}|{{.Spec.Labels.ssh_user}}' #{name}").split("|")
        user = "root" if user == "<no value>"
        new_nodes << Node.new(
          hostname: name,
          ip: ip,
          role: role,
          user: user
        )
      end
      new_nodes
    end

    def self.fetch_with_remote_ips(client : DockerClient, cluster : Cluster) : Array(Node)
      new_nodes = [] of Node
      service = Service.create(
        SERVICE_NAME, cluster,
        image: "alpine",
        options: "--mode global --restart-condition on-failure --detach --quiet",
        command: "sh -c 'apk add --no-cache curl jq && curl -s ipinfo.io | jq -r .ip'"
      )
      service.get_last_output_line.map do |line|
        name, ip = line.split
        role, user = client.exec("node inspect -f '{{.Spec.Role}}|{{.Spec.Labels.ssh_user}}' #{name}").split("|")
        user = "root" if user == "<no value>"
        new_nodes << Node.new(
          hostname: name,
          ip: ip,
          role: role,
          user: user
        )
      end
      service.rm!
      new_nodes
    end
  end
end
