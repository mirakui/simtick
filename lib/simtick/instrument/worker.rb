require 'simtick/instrument'
require 'simtick/instrument/waitable'

module Simtick
  module Instrument
    class Worker < Base
      include Waitable

      def initialize
        @current_payload = nil
      end

      def request(payload, &callback)
        if busy?
          callback.call payload.set(status: 503, body: 'worker is busy')
        else
          @current_payload = payload
          wait(100) do
            callback.call payload.set(status: 200, body: 'it works')
            @current_payload = nil
          end
        end
      end

      def busy?
        !!@current_payload
      end
    end
  end
end
