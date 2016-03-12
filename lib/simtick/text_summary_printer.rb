require 'simtick/base_printer'

module Simtick
  class TextSummaryPrinter < BasePrinter
    def initialize(result)
      @result = result
    end

    def print_device(dev)
      dev.puts @result.summarize
    end
  end
end
