module Simtick
  class Payload
    attr_reader :request_id
    attr_accessor :uri, :body, :status

    def initialize(uri:'/')
      @uri = uri
      @request_id = self.class.make_request_id
    end

    def set(uri:nil, body:nil, status:nil)
      @uri = uri if uri
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
