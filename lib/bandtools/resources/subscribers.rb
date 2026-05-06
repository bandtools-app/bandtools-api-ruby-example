# frozen_string_literal: true

require_relative '../transport'

module BandTools
  module Resources
    class Subscribers
      def initialize(transport)
        @transport = transport
      end

      def list(page: nil, per_page: nil, sort: nil, filter: nil)
        @transport.request_json(
          'GET',
          '/subscribers',
          query: { page:, per_page:, sort:, filter: }
        )
      end

      def add(email_address)
        @transport.request_json('POST', '/subscribers', json_body: { email_address: })
      end

      def delete_all
        @transport.request_json('DELETE', '/subscribers', query: { confirm: 'true' })
      end

      def get(subscriber_id)
        @transport.request_json('GET', "/subscribers/#{subscriber_id}")
      end

      def delete(subscriber_id)
        @transport.request_none('DELETE', "/subscribers/#{subscriber_id}")
      end

      def import_emails(email_addresses)
        @transport.request_json(
          'POST',
          '/subscribers/imports',
          json_body: { email_addresses: Array(email_addresses) }
        )
      end

      def import_csv(csv_path)
        upload = Transport::FileUpload.new('file', csv_path, 'text/csv')
        @transport.request_json('POST', '/subscribers/imports', file_upload: upload)
      end

      def import(import_id)
        @transport.request_json('GET', "/subscribers/imports/#{import_id}")
      end
    end
  end
end
