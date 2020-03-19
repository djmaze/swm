require "admiral"
require "./cluster/*"

module Swm
  class ClusterCommand < Admiral::Command
    define_help description: "Cluster commands"

    register_sub_command "add", AddCluster
    register_sub_command "env", GetEnv
    register_sub_command "fetch", FetchNodes
    register_sub_command "id", ClusterID
    register_sub_command "info", ClusterInfo
    register_sub_command "list", ListClusters
    register_sub_command "rm", RemoveCluster

    def run
      puts help
    end
  end
end
