module Simtick
  module Instrument
    class Base
      attr_accessor :sequencer

      def on_tick(ticker)
      end
    end
  end
end
