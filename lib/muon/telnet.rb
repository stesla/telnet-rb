require 'muon/telnet/constants'
require 'muon/telnet/stream'

module Muon
  module Telnet
    def self.on(io)
      Muon::Telnet::Stream.new(Muon::IoStream.new(io))
    end

    def self.to(host, port)
      on(TCPSocket.new(host, port))
    end
  end
end
