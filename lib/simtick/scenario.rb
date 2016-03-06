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

      proxy = Instrument::Proxy.new backlog: 1000, timeout: 205
      sequencer.add_track proxy

      workers = 1.times do |i|
        worker = Instrument::Worker.new
        sequencer.add_track worker
        proxy.add_worker worker
      end

      gen = Instrument::Generator.new(out: proxy, req_per_tick: 0.02)
      sequencer.add_track gen

      sequencer.play
    end
  end
end
