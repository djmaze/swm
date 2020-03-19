require "admiral"
require "./stack/*"

module Swm
  class StackCommand < Admiral::Command
    define_help description: "Stack commands"

    register_sub_command "deploy", Deploy
    register_sub_command "wait-for-deploy", WaitForStackDeploy

    def run
      puts help
    end
  end
end
