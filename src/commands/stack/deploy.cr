require "poncho"

require "../swm_command"
require "../../docker/stack"

module Swm
  class Deploy < Admiral::Command
    include SwmCommand

    rescue_from_errors

    define_help description: "deploy a swarm stack from a given compose file"
    define_argument :stack,
      description: "name of stack to deploy",
      required: true
    define_flag app_replicas : Int32,
      description: "number of app replicas",
      default: 1,
      long: "app-replicas"
    define_flag compose_file : String,
      description: "compose file to use (default: \"<stack>.yml\")",
      long: "compose-file"
    define_flag environment : String,
      description: "application environment (includes environment file from \"secrets/<STACK>/stack.env\""
    define_flag env_file : String,
      description: "environment file to include"
    define_flag predeploy : String,
      description: "predeploy script to run inside the script container"
    define_flag postdeploy : String,
      description: "postdeploy script to run inside the script container"
    define_flag script_service : String,
      description: "service to watch during predeploy / postdeploy",
      long: "script-service",
      default: "app"

    def run
      env = {} of String => String

      stack_yml = flags.compose_file || "#{arguments.stack}.yml"
      stack = Stack.new(arguments.stack, cluster: cluster, yml: stack_yml)
      app_replicas = flags.app_replicas

      env_file = if flags.env_file
        flags.env_file
      elsif File.exists? environment_file(arguments.stack)
        environment_file(arguments.stack)
      end

      if env_file
        info "Using environment from \"#{env_file}\""
        poncho = Poncho.from_file env_file
        env = poncho.to_h
      end

      if (flags.predeploy || flags.postdeploy) && !stack.exists?
        info "Stack \"#{stack.to_s}\" has not yet been deployed."
        info "Deploying stack \"#{stack.to_s}\" from #{stack_yml} for the first time with 0 app replicas"
        stack.deploy replicas: 0, env: env
      end

      if flags.predeploy
        info "Running \"#{flags.predeploy}\" in stack \"#{stack.script_stack.name}\" using #{stack.script_stack.yml}"
        stack.script_stack.predeploy(flags.predeploy.not_nil!, env: env)
        stack.script_stack.follow(flags.script_service)
      end

      info "Deploying stack \"#{stack.to_s}\" from #{stack_yml} with #{app_replicas} app replicas"
      stack.deploy replicas: app_replicas, env: env
      stack.wait_for_deploy
      info "Stack \"#{stack.to_s}\" deployed."

      if flags.postdeploy
        info "Running \"#{flags.postdeploy}\" in stack \"#{stack.script_stack.name}\" using #{stack.script_stack.yml}"
        stack.script_stack.postdeploy(flags.postdeploy.not_nil!, env: env)
        stack.script_stack.follow(flags.script_service)
      end

    end

    private def environment_file(stack : String) String
      "secrets/#{stack}/stack.env"
    end
  end
end
