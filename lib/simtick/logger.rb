module Simtick
  class Logger
    def initialize(device=nil)
      @device = device || $stdout
    end

    def record(log)
      line = log.map {|k, v| "#{k}:#{v}" }.join("\t")
      @device.puts line
    end
  end
end
