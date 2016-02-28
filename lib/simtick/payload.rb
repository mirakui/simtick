module Simtick
  class Payload
    attr_reader :env

    def initialize(env)
      @env = env
    end
  end
end
