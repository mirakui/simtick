require 'simtick/timeline'

module Simtick
  class Sequencer
    attr_reader :ticker

    def initialize
      @timelines = []
      @ticker = 0
      @id_counters = Hash.new {|h, k| h[k] = 0 }
    end

    def make_timeline
      Timeline.new(self).tap do |timeline|
        @timelines << timeline
      end
    end

    def tick!
      @timelines.each do |timeline|
        timeline.on_tick
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
