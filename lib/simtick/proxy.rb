require 'simtick/worker'
require 'simtick/loggable'

module Simtick
  class Proxy
    include Loggable

    def initialize(sequencer)
      super
      @sequencer = sequencer
      @timeline = sequencer.make_timeline
      @workers = []
      record :created
    end

    def add_worker(worker)
      @workers << worker
    end

    def request(payload)
      @timeline.add_interval(1)
      @timeline.add_action do |age|
        record :envoke_payload, payload: payload.to_s
        age < 10
        #false
      end
      #@timeline.add_action do |age|
      #  worker = @workers.sample
      #  worker.request payload
      #end
      @timeline.add_interval(1)
    end

    def record(event, tags={})
      tags = { timeline: @timeline.name }.merge tags
      super event, tags
    end
  end
end
