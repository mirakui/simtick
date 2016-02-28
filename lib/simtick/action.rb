module Simtick
  class Action
    def initialize(&block)
      @block = block
      @age = 0
      @running = true
    end

    def on_tick
      if @running
        @running = @block.call @age
        @age += 1
      end
      @running
    end

    def running?
      @running
    end
  end
end
