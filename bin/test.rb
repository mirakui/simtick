#!/usr/bin/env ruby

$: << File.expand_path('../lib', __dir__)
require 'simtick/scenario'

Simtick::Scenario.new.play
