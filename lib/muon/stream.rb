module Muon
  class Stream
    def initialize
      @buffer = ''
    end

    def at_end?
      buffer_empty? and internal_at_end?
    end

    def data_available?
      not buffer_empty? or internal_data_available?
    end

    def next
      return nil unless data_available?
      retrieve_data if buffer_empty?
      @buffer.slice!(0)
    end

    def next_all_in_buffer
      @buffer.slice!(0,@buffer.size)
    end

    def next_available
      retrieve_available
      next_all_in_buffer
    end

    def print(string)
      raise NotImplementedError
    end

    def put_all(cs)
      cs.each {|c| putc c}
    end

    def putc(c)
      raise NotImplementedError
    end

    def puts(string)
      print "#{string}\n"
    end

    def retrieve_available
      retrieve_data if data_available?
    end

    def retrieve_data
      internal_retrieve_data(@buffer)
    end

    protected

    def internal_at_end?
      raise NotImplementedError
    end

    def internal_data_available?
      raise NotImplementedError
    end

    def internal_retrieve_data(buffer)
      raise NotImplementedError
    end

    def buffer_empty?
      @buffer.empty?
    end
  end
end
