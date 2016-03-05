module Simtick
  module Instrument
    module Waitable
      def initialize
        @current_wait = nil
      end

      def on_tick(ticker)
        if @current_wait
          if @wait_progress >= @current_wait
            @wait_callback.call
            @current_wait = nil
          else
            @wait_progress += 1
          end
        end
      end

      def wait(interval, &block)
        @current_wait = interval
        @wait_progress = 1
        @wait_callback = block
      end
    end
  end
end
