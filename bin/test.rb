#!/usr/bin/env ruby

$: << File.expand_path('../lib', __dir__)
require 'simtick'
require 'simtick/sequencer'
require 'simtick/instrument/proxy'
require 'simtick/instrument/worker'
require 'simtick/instrument/generator'

sequencer = Simtick::Sequencer.new

proxy = Simtick::Instrument::Proxy.new(
  name: 'proxy-1',
  backlog: 2048,
  timeout: 20_000,
)
sequencer.add_track proxy

workers = 12.times do |i|
  worker = Simtick::Instrument::Worker.new do |payload|
    { duration: 300, status: 200, body: 'OK' }
    #{ duration: [10,20,170,1000].sample, status: 200, body: 'OK' }
  end
  sequencer.add_track worker
  proxy.add_worker worker
end

gen_opts = {
  out: proxy,
  name: 'gen-1',
  req_per_tick: 100.0 / 1000.0,
  attack_time: 20_000,
  sustain_time: 0,
  release_time: 0,
}

gen = Simtick::Instrument::Generator.new(gen_opts) do |t|
  { uri: "/" }
end

sequencer.add_track gen

unless ENV['SKIP_PLAY']
  sequencer.play
end

require 'simtick/html_printer'

printer = Simtick::HtmlPrinter.new(sequencer.result, ticks_per_sec: 1000)
out_path = 'tmp/out.html'
printer.print out_path
system 'open', out_path
