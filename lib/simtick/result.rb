require 'sqlite3'

module Simtick
  class Result
    FLUSH_INTERVAL = 1000
    TABLE_COLUMNS = {
      payloads: %w[ticker status reqtime],
      proxy_statuses: %w[ticker name backlog_used backlog_free workers_used workers_free],
    }

    def initialize
      @db = SQLite3::Database.new '/tmp/simtick.db'
      @buffers = Hash.new {|h,k| h[k] = [] }
      init_db
    end

    def record_payload(ticker:, status:, reqtime:)
      record_to_buffer :payloads, ticker, status, reqtime
    end

    def record_proxy_status(ticker:, name:, backlog_used:, backlog_free:, workers_used:, workers_free:)
      record_to_buffer :proxy_statuses, ticker, name, backlog_used, backlog_free, workers_used, workers_free
    end

    def record_to_buffer(table, *row)
      @buffers[table] << row
      @buffers.each do |table, rows|
        flush table if rows.length >= FLUSH_INTERVAL
      end
    end

    def flush(table)
      rows = @buffers[table]
      return if rows.empty?
      sql = instert_sql table, rows
      @db.execute sql
      @buffers[table].clear
    end

    def flush_all
      TABLE_COLUMNS.each_key {|table| flush table }
    end

    def instert_sql(table, rows)
      cols = TABLE_COLUMNS[table.intern]
      values = rows.map do |row|
        # FIXME: how do I use placeholders in bulk-insert?
        "(#{row.map {|r| "'#{r}'" }.join(',')})"
      end.join(',')
      "INSERT INTO `#{table}` (#{cols.map{|c| "`#{c}`" }.join(',')}) VALUES #{values}"
    end

    def summarize
      total_requests, avg_reqtime = @db.get_first_row(
        'SELECT COUNT(1), AVG(`reqtime`) FROM `payloads`'
      )
      statuses = @db.execute(
        'SELECT `status`, COUNT(`status`) FROM `payloads` GROUP BY `status`'
      )
      statuses = Hash[ statuses ]

      {
        total_requests: total_requests,
        avg_reqtime: avg_reqtime,
        statuses: statuses,
      }
    end

    def init_db
      @db.execute_batch <<-SQL
DROP TABLE IF EXISTS `payloads`;
CREATE TABLE `payloads` (
`id` INTEGER PRIMARY KEY AUTOINCREMENT,
`ticker` INTEGER NOT NULL,
`status` INTEGER NOT NULL,
`reqtime` INTEGER NOT NULL
);
CREATE INDEX `idx_payloads1` ON `payloads` (`ticker`, `status`);
CREATE INDEX `idx_payloads2` ON `payloads` (`ticker`, `reqtime`);

DROP TABLE IF EXISTS `proxy_statuses`;
CREATE TABLE `proxy_statuses` (
`id` INTEGER PRIMARY KEY AUTOINCREMENT,
`ticker` INTEGER NOT NULL,
`name` VARCHAR(32) NOT NULL,
`backlog_used` INTEGER NOT NULL,
`backlog_free` INTEGER NOT NULL,
`workers_used` INTEGER NOT NULL,
`workers_free` INTEGER NOT NULL
);
CREATE INDEX `idx_proxy_statuses1` ON `proxy_statuses` (`ticker`);
      SQL
    end
  end
end
