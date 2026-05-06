# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'bandtools-api-ruby-example'
  spec.version = '0.1.0'
  spec.authors = ['BandTools Ltd.']
  spec.summary = 'Example Ruby client for the BandTools REST API.'
  spec.description = 'Example Ruby code for authenticating with and using the BandTools REST API.'
  spec.homepage = 'https://bandtools.app/help/api'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md']
  spec.require_paths = ['lib']
end
