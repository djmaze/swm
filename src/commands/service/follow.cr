require "../swm_command"

module Swm
  class Follow < Admiral::Command
    include SwmCommand

    rescue_from_errors

    define_help description: "follow output of a running service and wait for it to finish"
    define_argument :service,
      description: "name of service to follow",
      required: true

    def run
      info "Following service #{arguments.service}"

      Service.new(arguments.service, cluster).follow
    end
  end
end
