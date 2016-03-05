require 'simtick/instrument'

module Simtick
  module Instrument
    class Generator < Base
      def initialize(out:, req_per_tick:)
        @out = out
        @req_per_tick = req_per_tick
        @dda_fiber = dda @req_per_tick
        @last_id = 0
      end

      def on_tick(ticker)
        if @dda_fiber.resume
          generate
        end
      end

      def generate
        @last_id += 1
        payload = { url: '/', request_id: @last_id }
        t_start = sequencer.ticker
        puts "started: #{t_start}, payload:#{payload}"
        callback = -> resp {
          t_end = sequencer.ticker
          t =  t_end - t_start
          puts "#{t_end}, resp:#{resp}, time:#{t}"
        }
        @out.request payload, &callback
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
