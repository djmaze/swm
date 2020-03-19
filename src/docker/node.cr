require "json"

module Swm
  record Node,
    hostname : String,
    ip : String,
    role : String,
    user : String do

    include JSON::Serializable

    def ssh_host
      "#{user}@#{ip}"
    end

    def to_s
      hostname
    end

    def to_h
      sprintf "%-20s %-15s %s", "#{user}@#{hostname}", ip, role
    end
  end
end
