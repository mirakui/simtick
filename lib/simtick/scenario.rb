require 'simtick/proxy'
require 'simtick/worker'
require 'simtick/sequencer'
require 'simtick/payload'

module Simtick
  class Scenario
    def initialize
    end

    def play
      sequencer = Sequencer.new

      #sequencer.add_track Instrument::Visitor, name: 'visitor1'

      track = sequencer.make_track

      proxy = Proxy.new(sequencer)
      proxy.add_worker(Worker.new(sequencer))

      payload = Payload.new path: '/foo'

      track.add_event { proxy.request payload }
      track.add_interval(100)
      track.add_event { proxy.request payload }
      track.add_interval(100)
      track.add_event { proxy.request payload }
      track.add_interval(100)

      sequencer.play
    end
  end
end
