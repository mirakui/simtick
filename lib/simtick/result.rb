require 'sqlite3'

module Simtick
  class Result
    def initialize(ticker_range:100)
      @ticker_range = ticker_range
      @db = SQLite3::Database.new '/tmp/simtick.db'
      init_db
    end

    def record(ticker:, status:, reqtime:)
      t = ticker / @ticker_range
      @db.execute <<-SQL, ticker, t, status, reqtime
INSERT INTO `payloads` (`ticker`, `ticker_range`, `status`, `reqtime`) VALUES (?, ?, ?, ?);
      SQL
    end

    def summarize
      total_requests = @db.execute(
        'SELECT COUNT(1) FROM `payloads`'
      ).first.first
      avg_reqtime = @db.execute(
        'SELECT AVG(`reqtime`) FROM `payloads`'
      ).first.first
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
      @db.execute 'DROP TABLE IF EXISTS `payloads`;'
      @db.execute <<-SQL
CREATE TABLE `payloads` (
`id` INTEGER PRIMARY KEY AUTOINCREMENT,
`ticker` INTEGER NOT NULL,
`ticker_range` INTEGER NOT NULL,
`status` INTEGER NOT NULL,
`reqtime` INTEGER NOT NULL
)
      SQL
      @db.execute 'CREATE INDEX `idx1` ON `payloads` (`ticker_range`, `status`)'
      @db.execute 'CREATE INDEX `idx2` ON `payloads` (`ticker_range`, `reqtime`)'
    end
  end
end
