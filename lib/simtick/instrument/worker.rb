require 'simtick/instrument'
require 'simtick/instrument/waitable'

module Simtick
  module Instrument
    class Worker < Base
      include Waitable

      def initialize(&block)
        @current_payload = nil
        raise ArgumentError, 'Worker.new must have a block' unless block
        @response_proc = block
      end

      def request(payload, &callback)
        if busy?
          callback.call payload.set(status: 503, body: 'worker is busy')
        else
          @current_payload = payload
          resp = @response_proc.call(payload)
          duration = resp[:duration] || 0
          status = resp[:status] || 200
          body = resp[:body] || 'it works'
          wait(duration) do
            callback.call payload.set(status: status, body: body)
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
