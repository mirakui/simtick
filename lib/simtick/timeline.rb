require 'simtick/action'
require 'simtick/loggable'

module Simtick
  class Timeline
    include Loggable

    def initialize(sequencer)
      super
      @sequencer = sequencer
      @actions = []
      record :created
    end

    def add_action(&block)
      action = Action.new(&block)
      record :action_registered, action: action.object_id
      @actions << action
    end

    def add_event(&block)
      add_action do |age|
        yield age
        false
      end
    end

    def add_interval(duration)
      add_action do |age|
        record :waiting_duration, age: age, duration: duration
        age < duration
      end
    end

    def on_tick
      if action = @actions.first
        action.on_tick
        unless action.running?
          record :action_finished, action: action.object_id
          @actions.shift
        end
      end
    end
  end
end
