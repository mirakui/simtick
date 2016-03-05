require 'simtick/instrument'

module Simtick
  module Instrument
    class Generator < Base
      DDA_RESOLUTION = 1000

      def initialize(out:, req_per_tick:)
        @out = out
        @req_per_tick = req_per_tick
        @dda_fiber = dda @req_per_tick
        @last_id = 0
      end

      def on_tick(ticker)
        n = @dda_fiber.resume
        if n && n > 0
          n.times { generate }
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
          dx = DDA_RESOLUTION
          dy = rpt * DDA_RESOLUTION

          ycount = 0
          err = dx - dy
          loop do
            e2 = err * 2
            if e2 > -dy
              err -= dy
              Fiber.yield ycount
              ycount = 0
            else
              Fiber.yield 0
            end
            if e2 < dx
              err += dx
              ycount += 1
            end
          end
        end
      end
    end
  end
end
