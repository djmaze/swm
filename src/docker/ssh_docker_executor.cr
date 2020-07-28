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
      signal_channel = Channel(Nil).new
      exit_channel = Channel(Nil).new
      output = show_output ? STDOUT : IO::Memory.new

      spawn do
        uri = URI.parse(@host)
        async_ssh_session = SSH2::Session.connect(uri.hostname.not_nil!)
        async_ssh_session.login_with_agent(uri.user.not_nil!)
        if watch
          buffer = IO::Memory.new
          loop do
            async_ssh_session.open_session do |channel|
              run_command_in_channel("docker " + command, channel, buffer)
              Process.run("clear", ["-x"], output: output, error: output)
              STDOUT.write(buffer.to_slice)

              if signal_channel.closed?
                exit_channel.send(nil)
                break
              else
                buffer.clear()
                sleep WATCH_INTERVAL_IN_SECONDS
              end
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
        if watch
          signal_channel.close
          exit_channel.receive
        end
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
