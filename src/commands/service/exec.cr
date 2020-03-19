require "../swm_command"

module Swm
  class Exec < Admiral::Command
    include SwmCommand

    rescue_from_errors

    define_help description: "run a command in a given service"
    define_argument :service,
      description: "name of service to run the command in",
      required: true
    define_argument :command,
      description: "command to execute in container",
      required: true
    define_flag :user,
      description: "user to execute as",
      long: "user",
      short: "u"
    define_flag no_tty : Bool,
      description: "disable pseudo-tty allocation",
      long: "no-tty",
      short: "T",
      default: false

    def run
      complete_command = [arguments.command, arguments[0..-1]].flatten.join(" ")
      service = Service.new(arguments.service, cluster)
      container = service.containers.sample
      info "Executing \"#{complete_command}\" in container #{container.id} on #{container.node.to_s}"
      container.exec complete_command, user: flags.user, no_tty: flags.no_tty, output: @output_io
    end
  end
end
