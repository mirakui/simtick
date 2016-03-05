require 'simtick/instrument'

module Simtick
  module Instrument
    class Worker < Base
      def initialize
        @current_payload = nil
      end

      def request(payload, callback)
        if @current_payload
          callback.resume( status: 503, body: 'worker is busy' )
        else
          @current_payload = payload
          sequencer.wait 50
          callback.resume( status: 200, body: 'it works' )
          @current_payload = nil
        end
      end
    end
  end
end
