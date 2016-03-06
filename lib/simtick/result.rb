module Simtick
  class Result
    def initialize(ticker_range:100)
      @ticker_range = ticker_range
      @statuses = Hash.new {|h,k| h[k] = Counter.new }
      @reqtimes = Counter.new
      @counts = Counter.new
    end

    def record(ticker:, status:, reqtime:)
      t = ticker / @ticker_range
      @statuses[status][t] += 1
      @reqtimes[t] += reqtime
      @counts[t] += 1
    end

    def summarize
      total_requests = @counts.sum
      avg_reqtime = @reqtimes.sum.to_f / total_requests
      statuses = Hash[ @statuses.map {|st,c| [st, c.sum] } ]
      {
        total_requests: total_requests,
        avg_reqtime: avg_reqtime,
        statuses: statuses,
      }
    end

    class Counter < Hash
      def initialize
        super {|h,k| h[k] = 0 }
      end

      def sum
        self.values.inject(0, &:+)
      end
    end
  end
end
