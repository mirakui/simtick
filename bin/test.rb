#!/usr/bin/env ruby

$: << File.expand_path('../lib', __dir__)
require 'simtick'
require 'simtick/sequencer'
require 'simtick/instrument/proxy'
require 'simtick/instrument/worker'
require 'simtick/instrument/generator'

sequencer = Simtick::Sequencer.new

proxy = Simtick::Instrument::Proxy.new backlog: 1000, timeout: 205
sequencer.add_track proxy

workers = 1.times do |i|
  worker = Simtick::Instrument::Worker.new do |payload|
    { duration: 100, status: 200, body: 'OK' }
  end
  sequencer.add_track worker
  proxy.add_worker worker
end

gen = Simtick::Instrument::Generator.new(out: proxy, req_per_tick: 0.02) do |t|
  { uri: "/hello?t=#{t}" }
end

sequencer.add_track gen

sequencer.play max_ticker: 1000

require 'simtick/text_summary_printer'
printer = Simtick::TextSummaryPrinter.new(sequencer.result)
printer.print(STDOUT)
