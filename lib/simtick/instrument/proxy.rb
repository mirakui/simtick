module Simtick
  module Instrument
    class Proxy < Base
      def initialize(backlog: 0, timeout: nil)
        @workers = []
        @backlog_max = backlog
        @backlog = []
        @timeoutable_tasks = []
        @timeout = timeout
      end

      def add_worker(worker)
        @workers << worker
      end

      def on_tick(ticker)
        check_timeoutable_tasks ticker
        while !@backlog.empty? && (worker = next_worker)
          task = @backlog.shift
          worker.request(task[:payload]) do |resp|
            task[:on_finish].call resp
          end
        end
      end

      def check_timeoutable_tasks(ticker)
        timedout_tasks = @timeoutable_tasks.select do |task|
          task[:timeout_at] && task[:timeout_at] <= ticker
        end
        timedout_tasks.each do |task|
          task[:on_timeout].call
          @timeoutable_tasks.delete task
        end
      end

      def request(payload, &callback)
        task = { payload: payload, callback: callback }
        if @timeout
          task[:timeout_at] = sequencer.ticker + @timeout
          task[:on_timeout] = -> {
            callback.call payload.set(status: 504, body: 'proxy timed out')
          }
          @timeoutable_tasks << task
        end

        if @backlog.empty?
          worker = next_worker
          if worker
            worker.request(payload) do |resp|
              finish_task task, resp
            end
            return
          end
        end

        if @backlog.length < @backlog_max
          task[:on_finish] = -> resp {
            finish_task task, resp
          }
          @backlog << task
        else
          finish_task task, payload.set(status: 503, body: 'proxy backlog limit exceeded')
        end
      end

      def finish_task(task, response)
        @timeoutable_tasks.delete task
        task[:callback].call response
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
