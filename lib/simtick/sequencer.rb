require 'simtick/track'

module Simtick
  class Sequencer
    attr_reader :ticker

    def initialize
      @tracks = []
      @ticker = 0
      @id_counters = Hash.new {|h, k| h[k] = 0 }
    end

    def add_track(inst)
      inst.sequencer = self
      @tracks << inst
    end

    def tick!
      #puts "ticker: #{@ticker}"
      @tracks.each do |track|
        track.on_tick @ticker
      end
      @ticker += 1
    end

    def play
      while @ticker <= 1000
        tick!
      end
    end

    def make_id(cls)
      @id_counters[cls] += 1
    end
  end
end
