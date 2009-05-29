require 'muon/stream'

module Muon
  class StringStream < Stream
    attr_accessor :input
    attr_accessor :output

    def initialize(string = '')
      super()
      @input = string.to_s.dup
      @output = ''
    end

    def print(s)
      output << s
    end

    def putc(c)
      print (Numeric === c ? c.chr : c)
    end

    protected

    def internal_at_end?
      not @input.empty?
    end

    def internal_data_available?
      not @input.empty?
    end

    def internal_retrieve_data(buffer)
      buffer << @input.slice!(0,@input.size)
    end
  end
end
