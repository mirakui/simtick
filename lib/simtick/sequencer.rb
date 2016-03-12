require 'simtick/result'

module Simtick
  class Sequencer
    attr_reader :ticker, :result

    def initialize(tick_per_sec: 1000)
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

    def play(max_ticker: 60_000)
      @result.init_db
      while @ticker <= max_ticker && !all_tracks_finished?
        tick!
      end
      @result.flush_all
    end

    def all_tracks_finished?
      @tracks.each do |t|
        return false if t.respond_to?(:finished?) && !t.finished?
        return false if t.respond_to?(:busy?) && t.busy?
      end
      true
    end

    def make_id(cls)
      @id_counters[cls] += 1
    end
  end
end
