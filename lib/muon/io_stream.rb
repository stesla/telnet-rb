require 'muon/stream'

module Muon
  class IoStream < Stream
    def initialize(io)
      raise ArgumentError, 'Must provide an IO' unless io.is_a? ::IO
      super()
      @io = io
      @at_end = false
    end

    def print(string)
      @io.write string
    end

    def putc(c)
      @io.putc c
    end

    protected

    def internal_at_end?
      @at_end
    end

    def internal_data_available?
      return false if at_end?
      return false unless io_data_available?
      retrieve_data
      data_available?
    end

    MAX_BUFFER = 512
    def internal_retrieve_data(buffer)
      data = @io.read_nonblock(MAX_BUFFER)
      if data.size > 0
        buffer << data
      else
        @at_end = true
      end
    rescue Errno::EAGAIN, Errno::EINTR, Errno::EWOULDBLOCK
    rescue EOFError
      @at_end = true
    end

    private

    def io_data_available?
      read, write, error = select([@io],[],[],0)
      read && read.first == @io
    end
  end
end
