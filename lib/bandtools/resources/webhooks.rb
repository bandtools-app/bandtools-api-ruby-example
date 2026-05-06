# frozen_string_literal: true

require_relative '../transport'

module BandTools
  module Resources
    class Webhooks
      def initialize(transport)
        @transport = transport
      end

      def list = @transport.request_json('GET', '/webhooks')

      def create(data) = @transport.request_json('POST', '/webhooks', json_body: data)

      def get(webhook_id) = @transport.request_json('GET', "/webhooks/#{webhook_id}")

      def update(webhook_id, data)
        @transport.request_json('PATCH', "/webhooks/#{webhook_id}", json_body: data)
      end

      def delete(webhook_id) = @transport.request_none('DELETE', "/webhooks/#{webhook_id}")

      def rotate_signing_secret(webhook_id)
        @transport.request_json('POST', "/webhooks/#{webhook_id}/rotate-signing-secret")
      end
    end
  end
end
