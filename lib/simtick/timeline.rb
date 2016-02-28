require 'simtick/action'

module Simtick
  class Timeline
    def initialize(sequencer)
      @sequencer = sequencer
      @actions = []
    end

    def add_action(&block)
      @actions << Action.new(&block)
    end

    def add_interval(duration)
      action = Action.new do |age|
        puts "waiting duration: #{age} / #{duration}"
        age < duration
      end
      @actions << action
    end

    def on_tick
      if action = @actions.first
        action.on_tick
        unless action.running?
          puts "action finished: #{action}"
          @actions.shift
        end
      end
    end
  end
end
