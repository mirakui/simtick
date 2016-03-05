module Simtick
  class Payload
    attr_reader :request_id
    attr_accessor :url, :body, :status

    def initialize(url:'/')
      @url = url
      @request_id = self.class.make_request_id
    end

    def set(url:nil, body:nil, status:nil)
      @url = url if url
      @body = body if body
      @status = status if status
      self
    end

    def self.make_request_id
      @last_request_id ||= 0
      @last_request_id += 1
    end
  end
end
