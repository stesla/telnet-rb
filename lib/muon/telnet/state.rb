module Muon
  module Telnet
    class State
      class CallbackArgs
        def initialize(*args)
          @buffer, @stream, @telnet = *args
        end
        attr_reader :buffer, :stream, :telnet
      end

      class << self
        def [] (name)
          states[name]
        end

        def states
          @states ||= Hash.new
        end
      end

      def initialize(name, &block)
        @name = name
        State.states[name] = self
        self.instance_eval(&block)
      end
      attr_reader :name

      def transition(buffer, stream, telnet)
        c = stream.next
        to_state, callback = transitions[c]
        callback.call(c, CallbackArgs.new(buffer, stream, telnet))
        State[to_state]
      end

      private

      def default(state = nil, &block)
        callback = block_given? ? block : nop_callback
        to_state = state || self.name
        transitions.default = [to_state,callback]
      end

      def nop_callback
        proc {|c, state|}
      end

      def on(spec, &block)
        callback = block_given? ? block : nop_callback
        case spec
        when Hash
          spec.each do |c,to_state|
            transitions[c] = [to_state,callback]
          end
        when Fixnum
          transitions[spec] = [self.name,callback]
        else
          raise ArgumentError, "Invalid transition spec"
        end
      end

      def transitions
        @transitions ||= Hash.new([self.name,nop_callback])
      end
    end
  end
end
