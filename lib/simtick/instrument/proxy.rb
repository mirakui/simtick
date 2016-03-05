module Simtick
  module Instrument
    class Proxy < Base
      def initialize(backlog: 0)
        @workers = []
        @backlog_max = backlog
        @backlog = []
      end

      def add_worker(worker)
        @workers << worker
      end

      def on_tick(ticker)
        while !@backlog.empty? && (worker = next_worker)
          task = @backlog.shift
          worker.request(task[:payload]) do |resp|
            task[:on_finish].call resp
          end
        end
      end

      def request(payload, &callback)
        if @backlog.empty?
          worker = next_worker
          if worker
            worker.request payload, &callback
            return
          end
        end

        if @backlog.length < @backlog_max
          task = { payload: payload, callback: callback }
          task[:on_finish] = -> resp {
            callback.call resp.merge(payload: payload)
          }
          task[:on_timeout] = -> resp {
            callback.call payload: payload, status: 504, body: 'proxy timed out'
          }
          @backlog << task
        else
          callback.call payload: payload, status: 503, body: 'proxy backlog limit exceeded'
        end
      end

      def next_worker
        @last_worker_index ||= 0
        len = @workers.length
        (0...len).each do |i|
          idx = (@last_worker_index + i) % len
          worker = @workers[idx]
          unless worker.busy?
            @last_worker_index = idx
            return worker
          end
        end
        nil # no workers available
      end
    end
  end
end
