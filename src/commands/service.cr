require "admiral"
require "./service/*"

module Swm
  class ServiceCommand < Admiral::Command
    define_help description: "Service commands"

    register_sub_command "follow", Follow
    register_sub_command "exec", Exec
    register_sub_command "restart", Restart

    def run
      puts help
    end
  end
end
