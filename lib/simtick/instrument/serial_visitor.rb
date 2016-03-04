require 'simtick/instrument'
require 'simtick/payload'

module Simtick
  module Instrument
    class SerialVisitor < Base
      def initialize(track, target:, payload: nil, timeout: nil, interval: 0)
        super track
        payload ||= Payload.new(path: '/')
        @target_note = nil
        @start_age = nil

        track.add_note do |age|
          if @target_note && @target_note.playing?
            if timeout && age - @start_age > timeout
              # request timed out
              @target_note = nil
            end
          else
            @start_age = age
            @target_note = target.play payload
          end

          true # infinite loop
        end
      end
    end
  end
end
