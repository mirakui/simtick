require 'simtick/instrument'

module Simtick
  module Instrument
    class Proxy < Base
      def initialize(name: nil, backlog: 0, timeout: 60_000)
        @workers = []
        @backlog_max = backlog
        @backlog = []
        @timeoutable_tasks = []
        @timeout = timeout
        @name = name || "proxy-#{object_id}"
      end

      def add_worker(worker)
        @workers << worker
      end

      def on_tick(ticker)
        check_timeoutable_tasks ticker
        while !@backlog.empty? && (worker = next_worker)
          task = @backlog.shift
          task[:worker] = worker
          worker.request(task[:payload]) do |resp|
            task[:on_finish].call resp
          end
        end
        record_proxy_status
      end

      def check_timeoutable_tasks(ticker)
        timedout_tasks = @timeoutable_tasks.select do |task|
          task[:timeout_at] && task[:timeout_at] <= ticker
        end
        timedout_tasks.each do |task|
          task[:on_timeout].call
          @timeoutable_tasks.delete task
          @backlog.delete task
        end
      end

      def request(payload, &callback)
        task = { payload: payload, callback: callback }
        if @timeout
          task[:timeout_at] = sequencer.ticker + @timeout
          task[:on_timeout] = -> {
            task[:worker].cancel if task[:worker]
            callback.call payload.set(status: 504, body: 'proxy timed out')
          }
          @timeoutable_tasks << task
        end

        if @backlog.empty?
          worker = next_worker
          if worker
            task[:worker] = worker
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

      def busy?
        @backlog.length > 0 || !!@workers.find(&:busy?)
      end

      def record_proxy_status
        workers_used = @workers.count(&:busy?)
        sequencer.result.record_proxy_status(
          ticker: sequencer.ticker,
          name: @name,
          backlog_used: @backlog.length,
          backlog_free: @backlog_max - @backlog.length,
          workers_used: workers_used,
          workers_free: @workers.length - workers_used,
        )
      end
    end
  end
end
