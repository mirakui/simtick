require 'simtick/track'

module Simtick
  class Sequencer
    attr_reader :ticker

    def initialize
      @tracks = []
      @ticker = 0
      @id_counters = Hash.new {|h, k| h[k] = 0 }
    end

    def make_track
      Track.new(self).tap do |track|
        @tracks << track
      end
    end

    def tick!
      @tracks.each do |track|
        track.on_tick
      end
      @ticker += 1
    end

    def start
      while @ticker <= 1000
        tick!
      end
    end

    def make_id(cls)
      @id_counters[cls] += 1
    end
  end
end
