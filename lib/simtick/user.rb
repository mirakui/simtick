require 'simtick/payload'

module Simtick
  class User
    def initialize(target, sequencer)
      @target = target
      @sequencer = sequencer
    end

    def add_event
      @sequencer.each_ticker do |ticker|
        if ticker % 100 == 0
          payload = Payload.new path: '/foo'
          @target.request payload
        end
      end
    end
  end
end
