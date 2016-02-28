require 'simtick/action'

module Simtick
  class Timeline
    def initialize(sequencer)
      @sequencer = sequencer
      @actions = []
    end

    def add_action(&block)
      action = Action.new(&block)
      puts "action registered: #{action}"
      @actions << action
    end

    def add_interval(duration)
      add_action do |age|
        puts "waiting duration: #{age} / #{duration}"
        age < duration
      end
    end

    def on_tick
      puts "remaining actions: #{@actions.length}"
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
