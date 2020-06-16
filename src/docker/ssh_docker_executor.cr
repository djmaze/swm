module Swm
  class SSHDockerExecutor
    WATCH_INTERVAL_IN_SECONDS = 2

    def initialize(@host : String)
      uri = URI.parse(@host)
      @ssh_session = SSH2::Session.connect(uri.hostname.not_nil!)
      @ssh_session.login_with_agent(uri.user.not_nil!)
    end

    def watch(command : String, &block)
      exec_async(command, show_output: true, watch: true, &block)
    end

    def exec_async(command : String, show_output = false, watch = false)
      output = show_output ? STDOUT : IO::Memory.new
      process = fork do
        uri = URI.parse(@host)
        async_ssh_session = SSH2::Session.connect(uri.hostname.not_nil!)
        async_ssh_session.login_with_agent(uri.user.not_nil!)
        if watch
          buffer = IO::Memory.new
          # Output result one more time when being killed
          Signal::INT.trap do
            async_ssh_session.open_session do |channel|
              buffer.clear()
              run_command_in_channel("docker " + command, channel, buffer)
              Process.run("clear", ["-x"], output: output, error: output)
              STDOUT.write(buffer.to_slice)
              exit
            end
          end
          while true
            async_ssh_session.open_session do |channel|
              run_command_in_channel("docker " + command, channel, buffer)
              Process.run("clear", ["-x"], output: output, error: output)
              STDOUT.write(buffer.to_slice)
              buffer.clear()
              sleep WATCH_INTERVAL_IN_SECONDS
            end
          end
        else
          async_ssh_session.open_session do |channel|
            run_command_in_channel("docker " + command, channel, output)
          end
        end
      end
      begin
        yield
      ensure
        process.kill(Signal::INT)
        process.wait
      end
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
