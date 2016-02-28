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
      proxy = Proxy.new(sequencer)
      proxy.add_worker(Worker.new(sequencer))

      payload = Payload.new path: '/foo'

      timeline = sequencer.make_timeline
      timeline.add_action { proxy.request payload; false }
      timeline.add_interval(100)
      timeline.add_action { proxy.request payload; false }
      timeline.add_interval(100)
      timeline.add_action { proxy.request payload; false }
      timeline.add_interval(100)

      sequencer.start
    end
  end
end
