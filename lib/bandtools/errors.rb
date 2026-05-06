# frozen_string_literal: true

module BandTools
  class Error < StandardError; end

  class APIError < Error
    attr_reader :api_message, :status_code, :response

    def initialize(status_code, message, response = nil)
      @api_message = message
      @status_code = status_code
      @response = response
      super(message)
    end

    def to_s
      "BandTools API error #{status_code}: #{api_message}"
    end

    def message
      api_message
    end
  end

  class ConnectionError < Error; end
end
