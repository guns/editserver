require 'socket'

module SocketTest
  class << self
    include Socket::Constants

    def open? host, port
      sock = Socket.new AF_INET, SOCK_STREAM, 0
      addr = Socket.sockaddr_in port, host
      sock.connect addr
      true
    rescue Errno::ECONNREFUSED
      false
    end
  end
end
