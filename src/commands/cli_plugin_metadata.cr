require "./swm_command"
require "json"

module Swm
  class CliPluginMetadata < Admiral::Command
    include SwmCommand

    def run
      puts(JSON.build do |json|
        json.object do
          json.field "SchemaVersion", "0.1.0"
          json.field "Vendor", "djmaze"
          json.field "Version", "v0.1.0"
          json.field "ShortDescription", "The missing tooling for a great Docker swarm experience"
          json.field "URL", "https://github.com/djmaze/swm"
        end
      end)
    end
  end
end
