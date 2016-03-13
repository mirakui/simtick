require 'simtick/base_printer'

module Simtick
  class HtmlPrinter < BasePrinter
    def initialize(result, ticks_per_sec: 1000)
      @result = result
      @ticks_per_sec = ticks_per_sec.to_i
    end

    def print_device(dev)
      rpts = sql_to_data <<-SQL
SELECT
  CAST(`ticker`/#{@ticks_per_sec} AS INTEGER) AS t,
  name,
  AVG(`rpt`) * #{@ticks_per_sec}
FROM `generator_statuses`
GROUP BY t, name
ORDER BY t
      SQL

      statuses = sql_to_data <<-SQL
SELECT
  CAST(`ticker`/#{@ticks_per_sec} AS INTEGER) AS t,
  `status`,
  COUNT(1) AS cnt
FROM `payloads`
GROUP BY t, status
ORDER BY t
      SQL

      reqtimes = sql_to_data <<-SQL
SELECT
  CAST(`ticker`/#{@ticks_per_sec} AS INTEGER) AS t,
  'reqtime',
  AVG(`reqtime`) / #{@ticks_per_sec} AS reqtime_avg
FROM `payloads`
GROUP BY t
ORDER BY t
      SQL

      proxies = sql_to_data2 <<-SQL
SELECT
  CAST(`ticker`/#{@ticks_per_sec} AS INTEGER) AS t,
  `name`,
  MAX(`workers_used`) AS workers_used,
  MIN(`workers_free`) AS workers_free,
  MAX(`backlog_used`) AS backlog_used,
  MIN(`backlog_free`) AS backlog_free
FROM `proxy_statuses`
GROUP BY t, name
ORDER BY t
      SQL

      print_html(dev) do
        print_graph dev, data: rpts, title: 'Requests per Second'
        print_graph dev, data: statuses, title: 'Status Codes per Second'
        print_graph dev, data: reqtimes, title: 'Average Request Time', type: 'scatter'
        proxies.each do |name, proxy|
          print_graph dev, data: proxy, title: "Proxy Status: #{name}"
        end
      end
    end

    private
    def sql_to_data(sql)
      data = {}
      @result.execute(sql) do |row|
        t, series, value = row
        data[series] ||= {}
        data[series][t] = value
      end
      data
    end

    def sql_to_data2(sql)
      rah = @result.db.results_as_hash
      @result.db.results_as_hash = true

      data = {}
      @result.execute(sql) do |row|
        t, series = row.values[0,2]
        data[series] ||= Hash.new {|h,k| h[k] = {} }
        keys = row.keys[2,(row.length/2-2)]
        keys.each do |k|
          data[series][k][t] = row[k]
        end
      end

      @result.db.results_as_hash = rah
      data
    end

    def print_html(dev, &block)
      dev.puts <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
</head>
<body>
      HTML

      yield

      dev.puts <<-HTML
</body>
</html>
      HTML
    end

    def print_graph(dev, data:, title:, type:'bar', errors:nil, width:'1000px', height:'400px')
      cls = "div#{data.object_id}"

      dev.puts <<-HTML
<div id="#{cls}" style="width: #{width}; height: #{height};"></div>
<script type="text/javascript">
      HTML

      trace_vars = []
      data.each do |series, trace|
        trace_var = "trace#{trace.object_id}"
        trace_vars << trace_var

        dev.puts <<-HTML
var #{trace_var} = {
  x: [#{trace.keys.join(',')}],
  y: [#{trace.values.join(',')}],
  type: '#{type}',
  mode: 'lines+markers',
  name: '#{series}'
};
        HTML
      end

      dev.puts <<-HTML
var data = [#{trace_vars.join(',')}];
var layout = {
#{type == 'bar' ? "barmode: 'stack'," : ''}
  title: '#{title}'
};
Plotly.newPlot('#{cls}', data, layout);
</script>
      HTML
    end
  end
end
