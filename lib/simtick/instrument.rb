module Simtick
  module Instrument
    class Base
      attr_reader :track

      def initialize(track)
        @track = track
      end
    end
  end
end
