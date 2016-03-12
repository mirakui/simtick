require 'simtick'
require 'simtick/payload'
require 'simtick/instrument'
require 'simtick/envelope'

module Simtick
  module Instrument
    class Generator < Base
      DDA_RESOLUTION = 1000

      def initialize(out:, req_per_tick:, attack_time:, sustain_time:0, release_time:0 , &block)
        @out = out
        @req_per_tick = req_per_tick
        @envelope = Envelope.new(
          velocity: req_per_tick, attack_time: attack_time,
          sustain_time: sustain_time, release_time: release_time
        )
        @dda_fiber = dda_fiber
        @payload_proc = block || lambda {|t| { uri: '/' } }
      end

      def on_tick(ticker)
        n = @dda_fiber.resume
        if n && n > 0
          n.times { generate }
        end
      end

      def generate
        payload = Payload.new @payload_proc.call(sequencer.ticker)
        t_start = sequencer.ticker
        callback = -> resp {
          t_end = sequencer.ticker
          t =  t_end - t_start
          Simtick.logger.record(
            ticker: t_end,
            uri: payload.uri,
            status: payload.status,
            reqid: payload.request_id,
            reqtime: t,
            body: payload.body,
          )
          sequencer.result.record(
            ticker: t_end,
            status: payload.status,
            reqtime: t,
          )
        }
        @out.request payload, &callback
      end

      def current_level
        @envelope.level sequencer.ticker
      end

      def finished?
        @envelope.finished? sequencer.ticker
      end

      # Bresenham's line algorithm
      def dda_fiber
        Fiber.new do
          dx = DDA_RESOLUTION
          dy = current_level * DDA_RESOLUTION

          ycount = 0
          err = dx - dy
          loop do
            dy = current_level * DDA_RESOLUTION
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
