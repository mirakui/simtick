#!/usr/bin/env ruby

$: << File.expand_path('../lib', __dir__)
require 'simtick'
require 'simtick/sequencer'
require 'simtick/instrument/proxy'
require 'simtick/instrument/worker'
require 'simtick/instrument/generator'

sequencer = Simtick::Sequencer.new

proxy = Simtick::Instrument::Proxy.new backlog: 1000, timeout: 20_000
sequencer.add_track proxy

workers = 1.times do |i|
  worker = Simtick::Instrument::Worker.new do |payload|
    { duration: 100, status: 200, body: 'OK' }
  end
  sequencer.add_track worker
  proxy.add_worker worker
end

gen_opts = {
  out: proxy,
  req_per_tick: 0.1,
  attack_time: 10_000,
  sustain_time: 5_000,
  release_time: 5_000,
}

gen = Simtick::Instrument::Generator.new(gen_opts) do |t|
  { uri: "/hello?t=#{t}" }
end

sequencer.add_track gen

sequencer.play

require 'simtick/text_summary_printer'
require 'simtick/html_printer'
printer = Simtick::TextSummaryPrinter.new(sequencer.result)
printer.print(STDOUT)

printer = Simtick::HtmlPrinter.new(sequencer.result)
out_path = 'tmp/out.html'
printer.print out_path
system 'open', out_path
