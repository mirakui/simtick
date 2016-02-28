module Simtick
  class Worker
    def initialize(sequencer)
      @sequencer = sequencer
    end

    def request(payload)
      @sequencer
    end
  end
end
