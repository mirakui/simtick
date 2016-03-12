require 'simtick/base_printer'

module Simtick
  class HtmlPrinter < BasePrinter
    def initialize(result)
      @result = result
    end

    def print_device(dev)
      rpts = sql_to_data <<-SQL
SELECT
  CAST(`ticker`/1000 AS INTEGER) * 1000 AS t,
  name,
  AVG(`rpt`)
FROM `generator_statuses`
GROUP BY t, name
ORDER BY t
      SQL

      reqtimes = sql_to_data <<-SQL
SELECT
  CAST(`ticker`/1000 AS INTEGER) * 1000 AS t,
  'reqtime',
  AVG(`reqtime`) AS reqtime
FROM `payloads`
GROUP BY t
ORDER BY t
      SQL

      statuses = sql_to_data <<-SQL
SELECT
  CAST(`ticker`/1000 AS INTEGER) * 1000 AS t,
  `status`,
  COUNT(1) AS cnt
FROM `payloads`
GROUP BY t, status
ORDER BY t
      SQL

      proxies = get_proxy_data

      print_html(dev) do
        print_graph dev, data: rpts, title: 'Requests per Tick'
        print_graph dev, data: reqtimes, title: 'Average Request Time'
        print_graph dev, data: statuses, title: 'Statuses'
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

    def get_proxy_data
      proxies = {}
      sql = <<-SQL
SELECT
  CAST(`ticker`/1000 AS INTEGER) * 1000 AS t,
  `name`,
  AVG(`backlog_used`) AS bu,
  AVG(`backlog_free`) AS bf,
  AVG(`workers_used`) AS wu,
  AVG(`workers_free`) AS wf
FROM `proxy_statuses`
GROUP BY t, name
ORDER BY t
      SQL
      @result.execute(sql) do |row|
        t, name, bu, bf, wu, wf = row
        proxies[name] ||= Hash.new {|h,k| h[k] = {} }
        proxies[name]['backlog used'][t] = bu
        proxies[name]['backlog free'][t] = bf
        proxies[name]['workers used'][t] = wu
        proxies[name]['workers free'][t] = wf
      end
      proxies
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

    def print_graph(dev, data:, title:, width:'1000px', height:'400px')
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
  type: 'scatter',
  mode: 'lines+markers',
  name: '#{series}'
};
        HTML
      end

      dev.puts <<-HTML
var data = [#{trace_vars.join(',')}];
var layout = {
  title: '#{title}'
};
Plotly.newPlot('#{cls}', data, layout);
</script>
      HTML
    end
  end
end
