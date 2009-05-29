require 'muon/stream'
require 'muon/telnet/options'
require 'muon/telnet/state'

module Muon
  module Telnet
    class Stream < Muon::Stream
      include Constants

      State.new :text do
        on IAC => :iac
        default do |c, state|
          state.buffer << c.chr
        end
      end

      State.new :iac do
        on DO => :do
        on DONT => :dont
        on SB => :subnegotiation
        on WILL => :will
        on WONT => :wont
        on IAC => :text do |c, state|
          state.buffer << c.chr
        end
        default :text
      end

      State.new :do do
        default :text do |c, state|
          state.telnet.received_do c
        end
      end

      State.new :dont do
        default :text do |c, state|
          state.telnet.received_dont c
        end
      end

      State.new :will do
        default :text do |c, state|
          state.telnet.received_will c
        end
      end

      State.new :wont do
        default :text do |c, state|
          state.telnet.received_wont c
        end
      end

      State.new :subnegotiation do
        on IAC => :subnegotiation_iac
      end

      State.new :subnegotiation_iac do
        on SE => :text
        default :subnegotiation
      end

      def initialize(stream)
        super()
        @stream = stream
        @state = State[:text]
      end

      def options
        @options ||= Options.new(@stream)
      end

      def print(s)
        s.each_byte {|c| putc c}
      end

      def putc(c)
        case c
        when IAC, IAC.chr
          @stream.putc(IAC)
          @stream.putc(IAC)
        else
          @stream.putc(c)
        end
      end

      def received_do(option)
        options.received_do option
      end

      def received_dont(option)
        options.received_dont option
      end

      def received_will(option)
        options.received_will option
      end

      def received_wont(option)
        options.received_wont option
      end

      protected

      def internal_at_end?
        @stream.at_end?
      end

      def internal_data_available?
        @stream.data_available?
      end

      def internal_retrieve_data(buffer)
        @state = @state.transition(buffer, @stream, self) while @stream.data_available?
      end
    end
  end
end
