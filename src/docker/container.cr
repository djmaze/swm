require "json"
require "./node"

module Swm
  record Container,
    id : String,
    task : String,
    node : Node do

      def to_s
        id
      end

      def exec(command : String, user : String? = nil, no_tty : Bool? = false, output : IO? = nil) : String
        options = [] of String
        options << "--user=#{user}" if user
        options << "-t" unless no_tty
        client.exec "exec -i #{options.join(" ")} #{id} #{command}", output: output
      end

      def stop
        client.exec "stop #{id}", node: node
      end
      
      private def client : DockerClient
        DockerClient.for_node(node)
      end
    end
end
