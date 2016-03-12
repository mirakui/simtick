module Simtick
  class Envelope
    def initialize(velocity:, attack_time:, sustain_time:0, release_time:0)
      @velocity = velocity
      @attack_time = attack_time
      @sustain_time = sustain_time
      @release_time = release_time
    end

    def level(ticker)
      if ticker <= @attack_time
        @velocity * (ticker / @attack_time.to_f)
      elsif ticker <= @attack_time + @sustain_time
        @velocity
      else
        t = ticker - @attack_time - @sustain_time
        @release_time > 0 ? [0.0, @velocity * (1.0 - t / @release_time)].max : 0.0
      end
    end

    def finished?(ticker)
      ticker > @attack_time + @sustain_time + @release_time
    end
  end
end
