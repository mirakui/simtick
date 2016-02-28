require 'simtick/proxy'
require 'simtick/user'
require 'simtick/worker'
require 'simtick/sequencer'

module Simtick
  class Scenario
    def initialize
    end

    def start
      sequencer = Sequencer.new
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

      sequencer.start
    end
  end
end
