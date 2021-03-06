require 'simtick'
require 'simtick/payload'
require 'simtick/instrument'
require 'simtick/envelope'

module Simtick
  module Instrument
    class Generator < Base
      DDA_RESOLUTION = 1000

      def initialize(name:nil, out:, req_per_tick:, attack_time:, sustain_time:0, release_time:0 , &block)
        @out = out
        @req_per_tick = req_per_tick
        @envelope = Envelope.new(
          velocity: req_per_tick, attack_time: attack_time,
          sustain_time: sustain_time, release_time: release_time
        )
        @dda_fiber = dda_fiber
        @payload_proc = block || lambda {|t| { uri: '/' } }
        @name = name || "generator-#{object_id}"
      end

      def on_tick(ticker)
        n = @dda_fiber.resume
        if n && n > 0
          n.times { generate }
        end
        sequencer.result.record_generator_status(
          ticker: ticker,
          name: @name,
          rpt: current_level,
        )
      end

      def generate
        payload = Payload.new @payload_proc.call(sequencer.ticker)
        t_start = sequencer.ticker
        callback = -> resp {
          t_end = sequencer.ticker
          t =  t_end - t_start
          Simtick.logger.record(
            ticker: t_start,
            uri: resp.uri,
            status: resp.status,
            reqid: resp.request_id,
            reqtime: t,
            body: resp.body,
          )
          sequencer.result.record_payload(
            ticker: t_end,
            status: resp.status,
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
