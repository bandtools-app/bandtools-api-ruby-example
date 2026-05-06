# frozen_string_literal: true

require_relative '../transport'

module BandTools
  module Resources
    class Newsletters
      def initialize(transport)
        @transport = transport
      end

      def list(page: nil, per_page: nil, status: nil)
        @transport.request_json(
          'GET',
          '/newsletters',
          query: { page:, per_page:, status: }
        )
      end

      def create(data) = @transport.request_json('POST', '/newsletters', json_body: data)

      def get(newsletter_id) = @transport.request_json('GET', "/newsletters/#{newsletter_id}")

      def update(newsletter_id, data)
        @transport.request_json('PATCH', "/newsletters/#{newsletter_id}", json_body: data)
      end

      def delete(newsletter_id) = @transport.request_none('DELETE', "/newsletters/#{newsletter_id}")

      def add_to_archive(newsletter_id)
        @transport.request_json('POST', "/newsletters/#{newsletter_id}/archive")
      end

      def remove_from_archive(newsletter_id)
        @transport.request_json('DELETE', "/newsletters/#{newsletter_id}/archive")
      end

      def duplicate(newsletter_id)
        @transport.request_json('POST', "/newsletters/#{newsletter_id}/duplicate")
      end

      def send_preview(newsletter_id, email_address)
        @transport.request_json(
          'POST',
          "/newsletters/#{newsletter_id}/preview",
          json_body: { email_address: }
        )
      end

      def send(newsletter_id)
        @transport.request_json('POST', "/newsletters/#{newsletter_id}/send")
      end

      def send_to_new_subscribers(newsletter_id)
        @transport.request_json('POST', "/newsletters/#{newsletter_id}/send-to-new-subscribers")
      end

      def schedule(newsletter_id, scheduled_for)
        @transport.request_json(
          'POST',
          "/newsletters/#{newsletter_id}/schedule",
          json_body: { scheduled_for: }
        )
      end

      def cancel_schedule(newsletter_id)
        @transport.request_json('DELETE', "/newsletters/#{newsletter_id}/schedule")
      end

      def pin(newsletter_id) = @transport.request_json('POST', "/newsletters/#{newsletter_id}/pin")

      def unpin(newsletter_id)
        @transport.request_json('DELETE', "/newsletters/#{newsletter_id}/pin")
      end

      def collaborators(newsletter_id)
        @transport.request_json('GET', "/newsletters/#{newsletter_id}/collaborators")
      end

      def invite_collaborator(newsletter_id, email_address)
        @transport.request_json(
          'POST',
          "/newsletters/#{newsletter_id}/collaborators",
          json_body: { email_address: }
        )
      end

      def revoke_collaborator(newsletter_id, collaborator_id)
        @transport.request_none(
          'DELETE',
          "/newsletters/#{newsletter_id}/collaborators/#{collaborator_id}"
        )
      end

      def acquire_lock(newsletter_id)
        @transport.request_json('POST', "/newsletters/#{newsletter_id}/lock")
      end

      def release_lock(newsletter_id)
        @transport.request_none('DELETE', "/newsletters/#{newsletter_id}/lock")
      end

      def refresh_lock(newsletter_id)
        @transport.request_json('PATCH', "/newsletters/#{newsletter_id}/lock/heartbeat")
      end

      def shared = @transport.request_json('GET', '/shared-newsletters')

      def upload_attachment(file_path)
        upload = Transport::FileUpload.new('file', file_path, nil)
        @transport.request_json('POST', '/newsletters/attachments', file_upload: upload)
      end
    end
  end
end
