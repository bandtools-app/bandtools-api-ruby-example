# frozen_string_literal: true

require_relative '../transport'

module BandTools
  module Resources
    class Account
      PAGES = %w[archive subscribe confirmation unsubscribe].freeze

      def initialize(transport)
        @transport = transport
      end

      def get = @transport.request_json('GET', '/account')

      def update(data) = @transport.request_json('PATCH', '/account', json_body: data)

      def download_picture = @transport.request_bytes('GET', '/account/picture')

      def upload_picture(image_path)
        @transport.request_json('PUT', '/account/picture', file_upload: file_upload(image_path))
      end

      def delete_picture = @transport.request_none('DELETE', '/account/picture')

      def settings = @transport.request_json('GET', '/account/settings')

      def update_settings(data)
        @transport.request_json('PATCH', '/account/settings', json_body: data)
      end

      def newsletter_settings = @transport.request_json('GET', '/account/newsletter-settings')

      def update_newsletter_settings(data)
        @transport.request_json('PATCH', '/account/newsletter-settings', json_body: data)
      end

      def themes = @transport.request_json('GET', '/account/themes')

      def create_theme(data)
        @transport.request_json('POST', '/account/themes', json_body: data)
      end

      def theme(theme_id) = @transport.request_json('GET', "/account/themes/#{theme_id}")

      def update_theme(theme_id, data)
        @transport.request_json('PATCH', "/account/themes/#{theme_id}", json_body: data)
      end

      def delete_theme(theme_id)
        @transport.request_none('DELETE', "/account/themes/#{theme_id}")
      end

      def page_design(page)
        @transport.request_json('GET', "/account/#{page_slug(page)}-page")
      end

      def update_page_design(page, data)
        @transport.request_json('PATCH', "/account/#{page_slug(page)}-page", json_body: data)
      end

      def upload_page_background_image(page, image_path)
        @transport.request_none(
          'PUT',
          "/account/#{page_slug(page)}-page/background-image",
          file_upload: file_upload(image_path)
        )
      end

      def delete_page_background_image(page)
        @transport.request_none('DELETE', "/account/#{page_slug(page)}-page/background-image")
      end

      def confirmation_email = @transport.request_json('GET', '/account/confirmation-email')

      def update_confirmation_email(data)
        @transport.request_json('PATCH', '/account/confirmation-email', json_body: data)
      end

      private

      def file_upload(path, content_type = nil)
        Transport::FileUpload.new('file', path, content_type)
      end

      def page_slug(page)
        slug = page.to_s
        return slug if PAGES.include?(slug)

        raise ArgumentError, "page must be one of: #{PAGES.join(', ')}"
      end
    end
  end
end
