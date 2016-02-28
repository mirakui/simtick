require 'simtick/worker'

module Simtick
  class Proxy
    def initialize(sequencer)
      @sequencer = sequencer
      @timeline = sequencer.make_timeline
      @workers = []
    end

    def add_worker(worker)
      @workers << worker
    end

    def request(payload)
      @timeline.add_interval(1)
      @timeline.add_action do |age|
        puts "proxy envoked an payload: #{payload}"
        false
      end
      #@timeline.add_action do |age|
      #  worker = @workers.sample
      #  worker.request payload
      #end
      @timeline.add_interval(1)
    end
  end
end
