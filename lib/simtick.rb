require 'simtick/version'
require 'simtick/logger'

module Simtick

  module_function
  def logger
    @logger ||= Simtick::Logger.new
  end
end
