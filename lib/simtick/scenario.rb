require 'simtick/sequencer'
require 'simtick/instrument/worker'
require 'simtick/instrument/generator'
require 'simtick/instrument/proxy'

module Simtick
  class Scenario
    def initialize
    end

    def play
      sequencer = Sequencer.new

      proxy = Instrument::Proxy.new backlog: 1
      sequencer.add_track proxy

      workers = 3.times do |i|
        worker = Instrument::Worker.new
        sequencer.add_track worker
        proxy.add_worker worker
      end

      gen = Instrument::Generator.new(out: proxy, req_per_tick: 0.03)
      sequencer.add_track gen

      sequencer.play
    end
  end
end
