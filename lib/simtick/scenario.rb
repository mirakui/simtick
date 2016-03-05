require 'simtick/sequencer'
require 'simtick/instrument/worker'
require 'simtick/instrument/generator'

module Simtick
  class Scenario
    def initialize
    end

    def play
      sequencer = Sequencer.new

      worker = Instrument::Worker.new
      sequencer.add_track worker

      gen = Instrument::Generator.new(out: worker, req_per_tick: 0.01)
      sequencer.add_track gen

      sequencer.play
    end
  end
end
