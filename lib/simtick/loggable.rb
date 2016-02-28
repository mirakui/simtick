require 'simtick'

module Simtick
  module Loggable
    def initialize(sequencer)
      id = sequencer.make_id(self.class)
      @name = "#{self.class.to_s.split('::').last.downcase}##{id}"
    end

    def record(event, tags={})
      log = { ticker: @sequencer.ticker, name: self.name, event: event }.merge(tags)
      Simtick.logger.record log
    end

    def name
      @name
    end
  end
end
