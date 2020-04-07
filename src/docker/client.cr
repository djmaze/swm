require "ssh2"

require "./service"

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
      uri = URI.parse(@host)
      @ssh_session = SSH2::Session.connect(uri.hostname.not_nil!)
      @ssh_session.login_with_agent(uri.user.not_nil!)
    end

    def wait_for(&block)
      while !yield
        sleep 5
      end
    end

    def exec(command : String, node : Node? = nil, replace = false, output = Process::Redirect::Inherit, input = Process::Redirect::Inherit, env = {} of String => String)
      if replace
        cmd, args = args_for command, node
        Process.new(cmd, args, input: input, output: output, error: output, env: env).wait
        output.to_s
      else
        raise "Input for ssh not allowed" if input != Process::Redirect::Inherit

        output = IO::Memory.new
        @ssh_session.open_session do |channel|
          run_command_in_channel("docker " + command, channel, output, env: env)
        end
        output.to_s.strip
      end
    end

    def watch(command : String, &block)
      exec_async(command, show_output: true, watch: true, &block)
    end

    def exec_async(command : String, show_output = false, watch = false)
      cmd, args = args_for command, watch: watch
      output = show_output ? STDOUT : IO::Memory.new
      columns = ENV.fetch("COLUMNS", "192").to_i
      process = fork do
        if watch
          Signal::TERM.trap do
            # reset watch PTY
            `reset`
            STDERR.puts
            exit
          end
        end
        uri = URI.parse(@host)
        async_ssh_session = SSH2::Session.connect(uri.hostname.not_nil!)
        async_ssh_session.login_with_agent(uri.user.not_nil!)
        async_ssh_session.open_session do |channel|
          exe = "docker"
          exe = "watch #{exe}" if watch
          channel.request_pty("vt102", width: columns)
          run_command_in_channel("#{exe} " + command, channel, output)
        end
      end
      begin
        yield
      ensure
        process.kill
        process.wait
      end
    end

    private def args_for(command : String, node : Node? = nil, watch = false) : {String, Array(String)}
      command_host = node ? "ssh://" + node.ssh_host : @host
      args = ["DOCKER_HOST=#{command_host} docker #{command}"]
      if watch
        cmd = "watch"
      else
        cmd = "sh"
        args.unshift "-c"
      end
      {cmd, args}
    end

    private def run_command_in_channel(command, channel, output, env = {} of String => String)
      env.each do |key, value|
        channel.setenv(key, value)
      end
      channel.command(command)  # TODO env
      IO.copy(channel, output)
      status = channel.exit_status
      if status != 0
        IO.copy(channel.err_stream, output)
        raise ArgumentError.new("Command #{command} failed on #{@host}. Exit status #{status}\n#{output.to_s}")
      end
    end
  end
end
