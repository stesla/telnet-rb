module Muon
  module Telnet
    class Option
      include Muon::Telnet::Constants

      def initialize(option, stream)
        @option = option
        @stream = stream
        @allow = false
        @him = :no
        @us = :no
      end
      attr_accessor :allow, :him, :us

      def enable_him
        @him = :want_yes_empty
        send_do
      end

      def disable_him
        @him = :want_no_empty
        send_dont
      end

      def enable_us
        @us = :want_yes_empty
        send_will
      end

      def disable_us
        @us = :want_no_empty
        send_wont
      end

      def enabled?
        @us == :yes and @him == :yes
      end

      def accept(field)
        case field
        when :him then send_do
        when :us then send_will
        end
      end

      def reject(field)
        case field
        when :him then send_dont
        when :us then send_wont
        end
      end

      def received_enable_request(field)
        var = "@#{field}"
        case instance_variable_get(var)
        when :no
          if @allow
            instance_variable_set(var, :yes)
            accept field
          else
            reject field
          end
        when :yes
        when :want_no_empty
          instance_variable_set(var, :no)
        when :want_no_opposite, :want_yes_empty
          instance_variable_set(var, :yes)
        when :want_yes_opposite
          instance_variable_set(var, :want_no_empty)
          reject field
        end
      end

      def received_disable_request(field)
        var = "@#{field}"
        case instance_variable_get(var)
        when :no
        when :yes
          instance_variable_set(var, :no)
          reject field
        when :want_no_opposite
          instance_variable_set(var, :want_yes_empty)
          accept field
        when :want_no_empty, :want_yes_empty, :want_yes_opposite
          instance_variable_set(var, :no)
        end
      end

      def received_do
        received_enable_request(:us)
      end

      def received_dont
        received_disable_request(:us)
      end

      def received_wont
        received_disable_request(:him)
      end

      def received_will
        received_enable_request(:him)
      end

      def send_do
        @stream.put_all [IAC, DO, @option]
      end

      def send_dont
        @stream.put_all [IAC, DONT, @option]
      end

      def send_will
        @stream.put_all [IAC, WILL, @option]
      end

      def send_wont
        @stream.put_all [IAC, WONT, @option]
      end
    end

    class Options
      def initialize(stream)
        @options = Hash.new do |hash, option|
          hash[option] = Option.new(option, stream)
        end
      end

      def [] (option)
        @options[option]
      end

      def []= (option, state)
        @options[option] = state
      end

      def received_do(option)
        self[option].received_do
      end

      def received_dont(option)
        self[option].received_dont
      end

      def received_will(option)
        self[option].received_will
      end

      def received_wont(option)
        self[option].received_wont
      end
    end
  end
end
