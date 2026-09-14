# frozen_string_literal: true

require 'test_helper'

class FakeHTTPResponse
  attr_reader :body, :code, :message

  def initialize(code: '200', body: '{"data":{"id":"acct_123"}}', headers: {})
    @code = code
    @body = body
    @message = 'OK'
    @headers = { 'Content-Type' => 'application/json' }.merge(headers)
  end

  def [](key)
    @headers[key]
  end
end

class FakeHTTPSuccess < FakeHTTPResponse; end

class FakeHTTPNoContent < FakeHTTPSuccess
  def initialize
    super(code: '204', body: '')
  end
end

class FakeHTTPError < FakeHTTPResponse; end

class FakeHTTP
  class << self
    attr_accessor :response, :requests, :uris

    def start(hostname, port, use_ssl:)
      http = new(hostname, port, use_ssl)
      yield http
    end
  end

  attr_accessor :read_timeout, :open_timeout

  def initialize(hostname, port, use_ssl)
    @hostname = hostname
    @port = port
    @use_ssl = use_ssl
  end

  def request(request)
    self.class.requests << request
    self.class.uris << [@hostname, @port, @use_ssl]

    response = self.class.response
    raise response if response.is_a?(Exception)

    response
  end
end

class BandToolsClientTest < Minitest::Test
  def setup
    FakeHTTP.response = FakeHTTPSuccess.new
    FakeHTTP.requests = []
    FakeHTTP.uris = []
  end

  def client(response = nil)
    FakeHTTP.response = response if response
    client = BandTools::Client.new(
      api_token: 'test-token',
      base_url: 'https://example.test/api/v1',
      timeout: 12.5
    )
    client.transport.http_client = FakeHTTP
    client
  end

  def last_request
    FakeHTTP.requests.last
  end

  def test_default_base_url_uses_production_api
    client = BandTools::Client.new(api_token: 'test-token')
    client.transport.http_client = FakeHTTP

    client.account.get

    assert_equal(['bandtools.app', 443, true], FakeHTTP.uris.last)
    assert_equal('/api/v1/account', last_request.path)
  end

  def test_get_request_adds_auth_headers_and_query_params
    result = client.subscribers.list(page: 2, per_page: 50, sort: 'email_desc')

    assert_equal({ 'data' => { 'id' => 'acct_123' } }, result)
    assert_instance_of(Net::HTTP::Get, last_request)
    assert_equal('/api/v1/subscribers?page=2&per_page=50&sort=email_desc', last_request.path)
    assert_equal('Bearer test-token', last_request['Authorization'])
    assert_equal('application/json', last_request['Accept'])
  end

  def test_account_response_includes_plan_features
    response = FakeHTTPSuccess.new(
      body: JSON.generate(
        data: {
          id: 'acct_123',
          social_links: {
            bandcamp: 'https://testuser.bandcamp.com',
            instagram: 'https://instagram.com/testuser'
          },
          features: {
            automatic_newsletters: true,
            duplicate_newsletter: true,
            subscriber_limit: 1000,
            unlimited_newsletters: true
          }
        }
      )
    )

    result = client(response).account.get

    assert(result.dig('data', 'features', 'automatic_newsletters'))
    assert_equal(1000, result.dig('data', 'features', 'subscriber_limit'))
    assert_equal('https://testuser.bandcamp.com', result.dig('data', 'social_links', 'bandcamp'))
    assert_equal('/api/v1/account', last_request.path)
  end

  def test_json_request_encodes_body
    response = FakeHTTPSuccess.new(code: '201', body: '{"data":{"id":"sub_123"}}')
    result = client(response).subscribers.add('fan@example.com')

    assert_equal({ 'data' => { 'id' => 'sub_123' } }, result)
    assert_instance_of(Net::HTTP::Post, last_request)
    assert_equal('application/json', last_request['Content-Type'])
    assert_equal({ 'email_address' => 'fan@example.com' }, JSON.parse(last_request.body))
  end

  def test_delete_returns_nil_for_no_content
    result = client(FakeHTTPNoContent.new).subscribers.delete('sub_123')

    assert_nil(result)
    assert_instance_of(Net::HTTP::Delete, last_request)
  end

  def test_binary_response_is_returned_as_bytes
    image = "\x89PNG\r\n".b
    response = FakeHTTPSuccess.new(body: image, headers: { 'Content-Type' => 'image/png' })

    assert_equal(image, client(response).account.download_picture)
  end

  def test_multipart_upload_sets_content_type_and_body
    response = FakeHTTPSuccess.new(code: '201', body: '{"data":{"id":"att_123"}}')
    Tempfile.create(['cover', '.jpg']) do |file|
      file.binmode
      file.write('image-bytes')
      file.close

      result = client(response).newsletters.upload_attachment(file.path)

      assert_equal({ 'data' => { 'id' => 'att_123' } }, result)
      assert_instance_of(Net::HTTP::Post, last_request)
      assert_includes(last_request['Content-Type'], 'multipart/form-data; boundary=')
      assert_includes(last_request.body, 'name="file"; filename="cover')
      assert_includes(last_request.body, 'Content-Type: image/jpeg')
      assert_includes(last_request.body, 'image-bytes')
    end
  end

  def test_attachment_uploads_use_api_supported_content_types
    response = FakeHTTPSuccess.new(code: '201', body: '{"data":{"id":"att_123"}}')
    content_types = {
      '.pdf' => 'application/pdf',
      '.m4a' => 'audio/mp4',
      '.mp3' => 'audio/mpeg',
      '.mp4' => 'video/mp4',
      '.mpeg' => 'video/mpeg'
    }

    content_types.each do |extension, content_type|
      Tempfile.create(['attachment', extension]) do |file|
        file.binmode
        file.write('attachment-bytes')
        file.close

        client(response).newsletters.upload_attachment(file.path)

        assert_includes(last_request.body, "Content-Type: #{content_type}")
      end
    end
  end

  def test_attachment_upload_allows_an_explicit_content_type_override
    response = FakeHTTPSuccess.new(code: '201', body: '{"data":{"id":"att_123"}}')
    Tempfile.create(['track', '.bin']) do |file|
      file.binmode
      file.write('audio-bytes')
      file.close

      client(response).newsletters.upload_attachment(file.path, content_type: 'audio/mp4')

      assert_includes(last_request.body, 'Content-Type: audio/mp4')
    end
  end

  def test_newsletter_updates_pass_collaborator_lock_versions
    client.newsletters.update('nws_123', { subject: 'Updated subject', lock_version: 7 })

    assert_instance_of(Net::HTTP::Patch, last_request)
    assert_equal('/api/v1/newsletters/nws_123', last_request.path)
    assert_equal(
      { 'subject' => 'Updated subject', 'lock_version' => 7 },
      JSON.parse(last_request.body)
    )
  end

  def test_newsletter_archive_and_duplicate_operations_use_schema_paths
    client.newsletters.add_to_archive('nws_123')
    client.newsletters.remove_from_archive('nws_123')
    client.newsletters.duplicate('nws_123')

    requests = FakeHTTP.requests.last(3)

    assert_instance_of(Net::HTTP::Post, requests[0])
    assert_equal('/api/v1/newsletters/nws_123/archive', requests[0].path)
    assert_instance_of(Net::HTTP::Delete, requests[1])
    assert_equal('/api/v1/newsletters/nws_123/archive', requests[1].path)
    assert_instance_of(Net::HTTP::Post, requests[2])
    assert_equal('/api/v1/newsletters/nws_123/duplicate', requests[2].path)
  end

  def test_newsletter_send_to_new_subscribers_uses_schema_path
    response = FakeHTTPSuccess.new(code: '202', body: '{"data":{"status":"queued"}}')
    result = client(response).newsletters.send_to_new_subscribers('nws_123')

    assert_equal({ 'data' => { 'status' => 'queued' } }, result)
    assert_instance_of(Net::HTTP::Post, last_request)
    assert_equal('/api/v1/newsletters/nws_123/send-to-new-subscribers', last_request.path)
  end

  def test_newsletter_schedule_uses_scheduled_for_request_field
    client.newsletters.schedule('nws_123', '2026-06-01T10:00:00Z')

    assert_instance_of(Net::HTTP::Post, last_request)
    assert_equal('/api/v1/newsletters/nws_123/schedule', last_request.path)
    assert_equal({ 'scheduled_for' => '2026-06-01T10:00:00Z' }, JSON.parse(last_request.body))
  end

  def test_update_social_links_uses_account_request_field
    client.account.update_social_links(
      bandcamp: 'https://testuser.bandcamp.com',
      instagram: 'https://instagram.com/testuser',
      youtube: nil
    )

    assert_instance_of(Net::HTTP::Patch, last_request)
    assert_equal('/api/v1/account', last_request.path)
    assert_equal(
      {
        'account' => {
          'social_links' => {
            'bandcamp' => 'https://testuser.bandcamp.com',
            'instagram' => 'https://instagram.com/testuser',
            'youtube' => nil
          }
        }
      },
      JSON.parse(last_request.body)
    )
  end

  def test_update_social_links_rejects_unrecognised_platforms_before_request
    assert_raises(ArgumentError) do
      client.account.update_social_links(myspace: 'https://example.com/testuser')
    end

    assert_empty(FakeHTTP.requests)
  end

  def test_api_error_uses_error_message_from_json_response
    body = JSON.generate({ error: { message: 'Email address is invalid' } })
    error = FakeHTTPError.new(code: '422', body:, headers: { 'Content-Type' => 'application/json' })

    exception = assert_raises(BandTools::APIError) do
      client(error).subscribers.add('not-an-email')
    end

    assert_equal(422, exception.status_code)
    assert_equal('Email address is invalid', exception.message)
    assert_equal({ 'error' => { 'message' => 'Email address is invalid' } }, exception.response)
  end

  def test_connection_errors_are_wrapped
    assert_raises(BandTools::ConnectionError) do
      client(SocketError.new('network down')).account.get
    end
  end

  def test_invalid_page_design_slug_is_rejected_before_request
    assert_raises(ArgumentError) do
      client.account.page_design(:landing)
    end

    assert_empty(FakeHTTP.requests)
  end
end
