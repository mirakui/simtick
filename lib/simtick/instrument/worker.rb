require 'simtick/instrument'
require 'simtick/instrument/waitable'

module Simtick
  module Instrument
    class Worker < Base
      include Waitable

      def initialize
        @current_payload = nil
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
    end
  end
end
