require "./node"

module Swm
  class LocalDockerExecutor
    def initialize(@default_host : String); end

    def exec(command : String, node : Node? = nil, show_output = false, output = Process::Redirect::Inherit, input = Process::Redirect::Inherit, env = {} of String => String) : String
      cmd, args = args_for command, node
      output = IO::Memory.new unless show_output
      Process.new(cmd, args, input: input, output: output, error: output, env: env).wait
      output.to_s.strip
    end

    private def args_for(command : String, node : Node? = nil) : {String, Array(String)}
      command_host = node ? "ssh://" + node.ssh_host : @default_host
      {"sh", ["-c", "DOCKER_HOST=#{command_host} docker #{command}"]}
    end
  end
end
