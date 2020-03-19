require "../swm_command"

module Swm
  class Restart < Admiral::Command
    include SwmCommand

    rescue_from_errors

    define_help description: "stop one container for the given service"
    define_argument :service,
      description: "name of service to restart",
      required: true

    def run
      container = Service.new(arguments.service, cluster).containers.sample
      info "Stopping container #{container.to_s} on #{container.node.to_s}"
      container.stop
    end
  end
end
