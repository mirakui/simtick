module Simtick
  class Payload
    attr_accessor :url, :request_id

    def initialize(url:)
      @url = url
    end
  end
end
