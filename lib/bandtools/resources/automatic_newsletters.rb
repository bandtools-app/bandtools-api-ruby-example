# frozen_string_literal: true

require_relative '../transport'

module BandTools
  module Resources
    class AutomaticNewsletters
      def initialize(transport)
        @transport = transport
      end

      def list = @transport.request_json('GET', '/automatic-newsletters')

      def create(data)
        @transport.request_json('POST', '/automatic-newsletters', json_body: data)
      end

      def get(automatic_newsletter_id)
        @transport.request_json('GET', "/automatic-newsletters/#{automatic_newsletter_id}")
      end

      def update(automatic_newsletter_id, data)
        @transport.request_json(
          'PATCH',
          "/automatic-newsletters/#{automatic_newsletter_id}",
          json_body: data
        )
      end

      def delete(automatic_newsletter_id)
        @transport.request_none('DELETE', "/automatic-newsletters/#{automatic_newsletter_id}")
      end

      def pause(automatic_newsletter_id)
        @transport.request_json('POST', "/automatic-newsletters/#{automatic_newsletter_id}/pause")
      end

      def resume(automatic_newsletter_id)
        @transport.request_json('POST', "/automatic-newsletters/#{automatic_newsletter_id}/resume")
      end

      def validate_feed(feed_url)
        @transport.request_json(
          'POST',
          '/automatic-newsletters/validate',
          json_body: { feed_url: }
        )
      end
    end
  end
end
