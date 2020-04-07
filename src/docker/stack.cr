module Swm
  class Stack
    getter name : String
    getter yml : String

    def initialize(@name : String, @cluster : Cluster, @yml : String = "#{name}.yml")
    end

    def exists?
      !client.exec("stack ps #{@name} || true").starts_with? "nothing found in stack"
    end

    def deploy(replicas = 1, env : Process::Env = {} of String => String)
      deploy_env = {
        "STACK" => name,
        "APP_REPLICAS" => replicas.to_s
      }.merge(env)

      preprocess_yaml(deploy_env) do |preprocessed_yml|
        client.exec(
          "stack deploy -c - --with-registry-auth #{name}",
          replace: true,
          input: IO::Memory.new(preprocessed_yml),
          env: deploy_env
        )
      end
    end

    def wait_for_deploy
      client.watch "stack ps #{name}" do
        client.wait_for { deployed? }
      end
    end

    def deployed? : Bool
      client.exec("stack ps -f desired-state=running -f desired-state=ready --format '{{ .DesiredState }} {{.CurrentState }}' #{name} | grep -v 'Running Running' || true").blank?
    end

    def script_stack
      script_yml = [File.basename(@yml, ".yml"), "_script.yml"].join
      @script_stack ||= Stack.new("#{name}_script", cluster: @cluster, yml: script_yml)
    end

    def predeploy(command : String)
      remove!
      deploy env: {
        "STACK" => original_stack_name,
        "SCRIPT_COMMAND" => command
      }
    end

    def postdeploy(command : String)
      remove!
      deploy env: {
        "STACK" => original_stack_name,
        "SCRIPT_COMMAND" => command
      }
    end

    def remove!
      client.exec "stack rm #{name}"
    end

    # name of the non-script stack
    def original_stack_name
      name.sub("_script", "")
    end

    def follow(service_name : String)
      complete_service_name = "#{name}_#{service_name}"
      Service.new(complete_service_name, cluster: @cluster).follow
    end

    def to_s
      @name
    end

    private def preprocess_yaml(env : Process::Env = {} of String => String, &block : String -> )
      content = File.read(yml)
      env.each do |key, value|
        content = content
          .gsub("$#{key}", value)
          .gsub("${#{key}}", value)
      end
      yield content
    end

    private def client : DockerClient
      DockerClient.for_cluster(@cluster)
    end
  end
end
