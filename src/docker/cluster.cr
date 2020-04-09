require "file_utils"
require "json"

require "./node_list_fetcher"

module Swm
  class Cluster
    include JSON::Serializable

    @@config_dir : String = File.join(ENV["HOME"], ".config/swm")

    @[JSON::Field]
    getter id : String

    @[JSON::Field]
    getter name : String?

    @[JSON::Field]
    getter nodes : Array(Node)

    @[JSON::Field]
    getter use_local_ips : Bool

    def self.all
      Dir.glob(File.join(@@config_dir, "*.json")).map do |path|
        Cluster.load(File.basename(path, ".json")).not_nil!
      end
    end

    def self.find(id_or_name : String) : Cluster?
      if File.exists?(filename(id_or_name))
        load(id_or_name)
      else
        cluster = all.find {|cluster| cluster.name == id_or_name }
        #raise ArgumentError.new("Cluster #{id_or_name} not found!") unless cluster
        return cluster
      end
    end

    def self.load_or_initialize(id : String, client : DockerClient) : Cluster
      load(id) || new(id, client)
    end

    def self.load(id : String) : Cluster?
      return unless File.exists?(filename(id))

      file = File.open(filename(id), "r")
      begin
        output = file.gets_to_end
      ensure
        file.close
      end
      from_json(output)
    end

    def initialize(@name : String, client : DockerClient, @use_local_ips = false)
      @id = fetch_id(client)
      @nodes = [] of Node
      save
    end

    def fetch_id(client)
      begin
        client.exec("info -f '{{.Swarm.Cluster.ID}}'")
      rescue
        sleep 1
        client.exec("info -f '{{.Swarm.Cluster.ID}}'")
      end
    end

    def fetch_nodes(client : DockerClient)
      @nodes = if use_local_ips
        NodeListFetcher.fetch_with_local_ips(client)
      else
        NodeListFetcher.fetch_with_remote_ips(client, self)
      end
      save
    end

    def load_nodes : Array(Node)
      file = File.open(filename, "r")
      begin
        output = file.gets_to_end
      ensure
        file.close
      end
      Array(Node).from_json(output)
    end

    def find_node(name : String) : Node?
      if nodes
        nodes.find {|node| node.hostname == name }
      else
        raise "nodes not fetched"
      end
    end

    def random_manager_node
      if nodes
        nodes
          .select {|node| node.role == "manager" }
          .sample
      else
        raise "nodes not fetched"
      end
    end

    def rm!
      FileUtils.rm filename
    end

    def to_s
      "#{name} (#{id})"
    end

    def to_h
      [
        "Name: #{name}",
        "ID: #{id}",
        "Nodes:",
        nodes.map do |node|
          "  #{node.to_h}"
        end
      ].flatten.join("\n")
    end

    def self.filename(id : String) : String
      File.join(@@config_dir, id + ".json")
    end

    private def save
      File.open(filename, "w") do |file|
        file.write to_json.to_slice
      end
    end

    private def filename
      self.class.filename(id)
    end
  end
end
