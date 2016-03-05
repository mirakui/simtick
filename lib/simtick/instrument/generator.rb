require 'simtick/instrument'

module Simtick
  module Instrument
    class Generator < Base
      def initialize(out:, req_per_tick:, tick_resolution: 1000)
        @out = out
        @req_per_tick = req_per_tick
        @tick_resolution = tick_resolution.to_i
        @dda_fiber = dda @req_per_tick
      end

      def on_tick(ticker)
        if @dda_fiber.resume
          generate
        end
      end

      def generate
        case @out
        when Array
          raise 'not implemented yet'
        else
          payload = { url: '/' }
          callback = Fiber.new do
            t_start = sequencer.ticker
            resp = Fiber.yield
            t = sequencer.ticker - t_start
            puts "#{t_start}, resp:#{resp}, time:#{t}"
          end
          callback.resume
          @out.request payload, callback
        end
      end

      # Bresenham's line algorithm
      def dda(rpt)
        Fiber.new do
          err = 0
          loop do
            err += rpt
            if err >= 0.5
              Fiber.yield true
              err -= 1.0
            else
              Fiber.yield false
            end
          end
        end
      end
    end
  end
end
