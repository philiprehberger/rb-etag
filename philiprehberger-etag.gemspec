# frozen_string_literal: true

require_relative 'lib/philiprehberger/etag/version'

Gem::Specification.new do |spec|
  spec.name = 'philiprehberger-etag'
  spec.version = Philiprehberger::Etag::VERSION
  spec.authors = ['Philip Rehberger']
  spec.email = ['me@philiprehberger.com']
  spec.summary = 'ETag generation and conditional request helpers with Rack middleware'
  spec.description = 'Generate strong and weak ETags, evaluate If-None-Match and If-Match headers, ' \
                     'and serve 304 Not Modified responses via included Rack middleware.'
  spec.homepage = 'https://philiprehberger.com/open-source-packages/ruby/philiprehberger-etag'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/philiprehberger/rb-etag'
  spec.metadata['changelog_uri'] = 'https://github.com/philiprehberger/rb-etag/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/philiprehberger/rb-etag/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
