require "../swm_command"

module Swm
  class WaitForStackDeploy < Admiral::Command
    #extend SwmCommand::ClassMethods
    include SwmCommand

    rescue_from_errors

    define_help description: "wait for a stack to be deployed successfully"
    define_argument :stack,
      description: "name of stack to wait for",
      required: true

    def run
      info "Waiting for deployment of stack #{arguments.stack}.."

      Stack.new(arguments.stack, cluster: cluster).wait_for_deploy

      info "Stack #{arguments.stack} deployed."
    end
  end
end
