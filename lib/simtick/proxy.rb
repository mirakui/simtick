require 'simtick/worker'
require 'simtick/loggable'

module Simtick
  class Proxy
    include Loggable

    def initialize(sequencer)
      super
      @sequencer = sequencer
      @track = sequencer.make_track
      @workers = []
      record :created
    end

    def add_worker(worker)
      @workers << worker
    end

    def request(payload)
      @track.add_interval(1)
      @track.add_action do |age|
        record :envoke_payload, payload: payload.to_s
        age < 10
        #false
      end
      #@track.add_action do |age|
      #  worker = @workers.sample
      #  worker.request payload
      #end
      @track.add_interval(1)
    end

    def record(event, tags={})
      tags = { track: @track.name }.merge tags
      super event, tags
    end
  end
end
