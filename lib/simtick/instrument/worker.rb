require 'simtick/instrument'

module Simtick
  module Instrument
    class Worker < Base
      def initialize
        @ticker_events = Hash.new {|h,k| h[k] = [] }
      end

      def request(payload, callback)
        f = lambda do
          resp = { status: 200, body: 'It works!' }
          callback.resume resp
        end

        t = sequencer.ticker + 5
        @ticker_events[t] << f
      end

      def on_tick(ticker)
        if @ticker_events.has_key?(ticker)
          events = @ticker_events[ticker]
          events.each do |e|
            e.call
          end
          @ticker_events.delete ticker
        end
      end
    end
  end
end
