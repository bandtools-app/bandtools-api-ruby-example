# frozen_string_literal: true

require_relative 'transport'
require_relative 'resources/account'
require_relative 'resources/automatic_newsletters'
require_relative 'resources/newsletters'
require_relative 'resources/subscribers'
require_relative 'resources/webhooks'

module BandTools
  class Client
    DEFAULT_BASE_URL = 'https://bandtools.app/api/v1'

    attr_reader :account, :automatic_newsletters, :newsletters, :subscribers, :webhooks, :transport

    def initialize(api_token:, base_url: DEFAULT_BASE_URL, timeout: 30)
      @transport = Transport.new(api_token:, base_url:, timeout:)
      @subscribers = Resources::Subscribers.new(@transport)
      @account = Resources::Account.new(@transport)
      @newsletters = Resources::Newsletters.new(@transport)
      @automatic_newsletters = Resources::AutomaticNewsletters.new(@transport)
      @webhooks = Resources::Webhooks.new(@transport)
    end
  end
end
