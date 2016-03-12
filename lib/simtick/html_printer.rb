require 'simtick/base_printer'

module Simtick
  class HtmlPrinter < BasePrinter
    def initialize(result)
      @result = result
    end

    def print_device(dev)
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

      rpts = sql_to_data <<-SQL
SELECT
  CAST(`ticker`/1000 AS INTEGER) * 1000 AS t,
  name,
  AVG(`rpt`)
FROM `generator_statuses`
GROUP BY t, name
ORDER BY t
      SQL

      print_html(dev) do
        print_graph dev, data: reqtimes, title: 'Average Request Time'
        print_graph dev, data: statuses, title: 'Statuses'
        print_graph dev, data: rpts, title: 'Requests per Tick'
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
