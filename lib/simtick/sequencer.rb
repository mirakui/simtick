require 'simtick/result'

module Simtick
  class Sequencer
    attr_reader :ticker, :result

    def initialize
      @tracks = []
      @ticker = 0
      @id_counters = Hash.new {|h, k| h[k] = 0 }
      @result = Result.new
    end

    def add_track(inst)
      inst.sequencer = self
      @tracks << inst
    end

    def tick!
      @tracks.each do |track|
        track.on_tick @ticker
      end
      @ticker += 1
    end

    def play(max_ticker: 1000)
      while @ticker <= max_ticker
        tick!
      end
    end

    def make_id(cls)
      @id_counters[cls] += 1
    end
  end
end
