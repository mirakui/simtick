require 'simtick/instrument'

module Simtick
  module Instrument
    class Worker < Base
      def initialize
        @current_payload = nil
        @current_wait = nil
      end

      def request(payload, callback)
        if @current_payload
          callback.resume( status: 503, body: 'worker is busy' )
        else
          @current_payload = payload
          wait(200) do
            callback.resume( status: 200, body: 'it works' )
            @current_payload = nil
          end
        end
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
