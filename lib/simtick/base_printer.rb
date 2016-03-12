module Simtick
  class BasePrinter
    def print(dev)
      case dev
      when String
        open(dev, 'w+') do |f|
          print_device f
        end
      when IO
        print_device dev
      else
        raise ArgumentError, "unknown output: #{dev}"
      end
    end

    def print_device(dev)
      raise 'not implemented yet'
    end
  end
end
