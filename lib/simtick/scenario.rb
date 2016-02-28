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
      timeline = sequencer.make_timeline

      proxy = Proxy.new(sequencer)
      proxy.add_worker(Worker.new(sequencer))

      payload = Payload.new path: '/foo'

      timeline.add_event { proxy.request payload }
      timeline.add_interval(100)
      timeline.add_event { proxy.request payload }
      timeline.add_interval(100)
      timeline.add_event { proxy.request payload }
      timeline.add_interval(100)

      sequencer.start
    end
  end
end
