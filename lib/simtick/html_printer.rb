require 'simtick/base_printer'
require 'json'

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

      ticker_max = get_ticker_max
      opts = {
        xaxis_range: [0, (ticker_max / @ticks_per_sec).to_i]
      }

      print_html(dev) do
        print_graph dev, opts.merge(data: rpts, title: 'Requests per Second')
        print_graph dev, opts.merge(data: statuses, title: 'Status Codes per Second')
        print_graph dev, opts.merge(data: reqtimes, title: 'Average Request Time', type: 'scatter')
        proxies.each do |name, proxy|
          print_graph dev, opts.merge(data: proxy, title: "Proxy Status: #{name}")
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

    def get_ticker_max
      tables = %w[proxy_statuses generator_statuses payloads]
      tables.map do |t|
        @result.db.get_first_value("SELECT MAX(`ticker`) FROM `#{t}`")
      end.max
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

    def print_graph(dev, data:, title:, type:'bar', xaxis_range:nil, width:'1000px', height:'400px')
      cls = "div#{data.object_id}"

      dev.puts <<-HTML
<div id="#{cls}" style="width: #{width}; height: #{height};"></div>
<script type="text/javascript">
      HTML

      trace_var_names = []
      data.each do |series, trace|
        trace_var_name = "trace#{trace.object_id}"
        trace_var_names << trace_var_name
        tv = {
          'x' => trace.keys,
          'y' => trace.values,
          'type' => type,
          'name' => series,
        }

        tv['mode'] = 'lines+markers' if type == 'scatter'

        print_var dev, trace_var_name, tv
      end

      layout = {
        'title' => title,
        'showlegend' => true,
      }
      layout['barmode'] = 'stack' if type == 'bar'
      layout['xaxis'] = { range: xaxis_range } if xaxis_range
      print_var dev, 'layout', layout

      dev.puts <<-HTML
var data = [#{trace_var_names.join(',')}]
Plotly.newPlot('#{cls}', data, layout);
</script>
      HTML
    end

    def print_var(dev, name, value)
      dev.puts "var #{name} = #{value.to_json}"
    end
  end
end
