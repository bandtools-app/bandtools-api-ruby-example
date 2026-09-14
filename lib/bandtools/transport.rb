# frozen_string_literal: true

require 'json'
require 'net/http'
require 'pathname'
require 'securerandom'
require 'timeout'
require 'uri'

require_relative 'errors'

module BandTools
  class Transport
    USER_AGENT = 'bandtools-api-ruby-example/0.1.0'
    MIME_TYPES = {
      '.csv' => 'text/csv',
      '.gif' => 'image/gif',
      '.jpeg' => 'image/jpeg',
      '.jpg' => 'image/jpeg',
      '.m4a' => 'audio/mp4',
      '.m4v' => 'video/mp4',
      '.mp3' => 'audio/mpeg',
      '.mp4' => 'video/mp4',
      '.mpeg' => 'video/mpeg',
      '.mpg' => 'video/mpeg',
      '.pdf' => 'application/pdf',
      '.png' => 'image/png',
      '.webp' => 'image/webp'
    }.freeze

    FileUpload = Struct.new(:field_name, :path, :content_type, keyword_init: false)

    attr_reader :api_token, :base_url, :timeout
    attr_accessor :http_client

    def initialize(api_token:, base_url:, timeout:)
      raise ArgumentError, 'api_token is required' if api_token.to_s.empty?

      @api_token = api_token
      @base_url = base_url.delete_suffix('/')
      @timeout = timeout
      @http_client = Net::HTTP
    end

    def request_json(method, path, query: nil, json_body: nil, file_upload: nil)
      response = request(method, path, query:, json_body:, file_upload:)
      return response if response.is_a?(Hash)

      raise APIError.new(0, 'Expected a JSON object response')
    end

    def request_bytes(method, path)
      response = request(method, path, expect_binary: true)
      return response if response.is_a?(String)

      raise APIError.new(0, 'Expected a binary response')
    end

    def request_none(method, path, query: nil, json_body: nil, file_upload: nil)
      request(method, path, query:, json_body:, file_upload:)
      nil
    end

    private

    def request(method, path, query: nil, json_body: nil, file_upload: nil, expect_binary: false)
      uri = build_uri(path, query)
      http_request = build_request(method, uri, json_body:, file_upload:)
      response = perform_request(uri, http_request)

      return nil if response.code.to_i == 204 || response.body.to_s.empty?
      return response.body if expect_binary

      parse_response(response)
    end

    def build_uri(path, query)
      uri = URI("#{base_url}#{path}")
      clean_query = query&.compact
      uri.query = URI.encode_www_form(clean_query) if clean_query&.any?
      uri
    end

    def build_request(method, uri, json_body: nil, file_upload: nil)
      request_class = Net::HTTP.const_get(method.capitalize)
      http_request = request_class.new(uri)
      http_request['Accept'] = 'application/json'
      http_request['Authorization'] = "Bearer #{api_token}"
      http_request['User-Agent'] = USER_AGENT

      apply_json_body(http_request, json_body) unless json_body.nil?
      apply_file_upload(http_request, file_upload) unless file_upload.nil?
      http_request
    end

    def apply_json_body(http_request, json_body)
      http_request['Content-Type'] = 'application/json'
      http_request.body = JSON.generate(json_body)
    end

    def apply_file_upload(http_request, upload)
      boundary = "bandtools-#{SecureRandom.hex}"
      http_request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
      http_request.body = multipart_body(upload, boundary)
    end

    def multipart_body(upload, boundary)
      path = Pathname.new(upload.path.to_s)
      content_type = upload.content_type || content_type_for(path)

      [
        "--#{boundary}",
        %(Content-Disposition: form-data; name="#{upload.field_name}"; filename="#{path.basename}"),
        "Content-Type: #{content_type}",
        '',
        path.binread,
        "--#{boundary}--",
        ''
      ].join("\r\n")
    end

    def content_type_for(path)
      MIME_TYPES.fetch(path.extname.downcase, 'application/octet-stream')
    end

    def perform_request(uri, http_request)
      http_client.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.read_timeout = timeout
        http.open_timeout = timeout
        response = http.request(http_request)
        raise_api_error(response) unless response.code.to_i.between?(200, 299)

        response
      end
    rescue SocketError, SystemCallError, Timeout::Error => e
      raise ConnectionError, e.message
    end

    def parse_response(response)
      content_type = response['Content-Type'].to_s
      return { 'data' => response.body } unless content_type.include?('application/json')

      JSON.parse(response.body)
    end

    def raise_api_error(response)
      parsed = parse_error_body(response.body)
      message = error_message(parsed) || response.message || 'Request failed'
      raise APIError.new(response.code.to_i, message, parsed)
    end

    def parse_error_body(body)
      return nil if body.to_s.empty?

      JSON.parse(body)
    rescue JSON::ParserError
      body
    end

    def error_message(parsed)
      return parsed unless parsed.is_a?(Hash)

      error = parsed['error']
      return error['message'] || error['detail'] if error.is_a?(Hash)

      parsed['message']
    end
  end
end
