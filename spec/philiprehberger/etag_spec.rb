# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::Etag do
  it 'has a version number' do
    expect(Philiprehberger::Etag::VERSION).not_to be_nil
  end

  describe '.generate' do
    it 'returns a quoted hex string' do
      etag = described_class.generate('hello world')
      expect(etag).to match(/\A"[a-f0-9]{64}"\z/)
    end

    it 'returns consistent results for the same content' do
      expect(described_class.generate('test')).to eq(described_class.generate('test'))
    end

    it 'returns different results for different content' do
      expect(described_class.generate('foo')).not_to eq(described_class.generate('bar'))
    end
  end

  describe '.weak' do
    it 'returns an ETag with the W/ prefix' do
      etag = described_class.weak('hello world')
      expect(etag).to match(%r{\AW/"[a-f0-9]{32}"\z})
    end

    it 'returns consistent results for the same content' do
      expect(described_class.weak('test')).to eq(described_class.weak('test'))
    end
  end

  describe '.match?' do
    let(:etag) { described_class.generate('hello') }

    it 'returns true when the ETag matches' do
      expect(described_class.match?(etag, etag)).to be true
    end

    it 'returns false when the ETag does not match' do
      expect(described_class.match?(etag, '"other"')).to be false
    end

    it 'matches with wildcard *' do
      expect(described_class.match?(etag, '*')).to be true
    end

    it 'matches in a comma-separated list' do
      header = %("aaa", #{etag}, "bbb")
      expect(described_class.match?(etag, header)).to be true
    end

    it 'performs weak comparison ignoring W/ prefix' do
      strong = described_class.generate('hello')
      digest = strong[1..-2] # strip outer quotes
      weak_etag = %(W/"#{digest}")
      expect(described_class.match?(strong, weak_etag)).to be true
    end

    it 'returns false for nil header' do
      expect(described_class.match?(etag, nil)).to be false
    end

    it 'returns false for empty header' do
      expect(described_class.match?(etag, '')).to be false
    end
  end

  describe '.strong_match?' do
    let(:etag) { described_class.generate('hello') }

    it 'returns true for an exact strong match' do
      expect(described_class.strong_match?(etag, etag)).to be true
    end

    it 'returns false when a weak ETag is provided' do
      weak = %(W/#{etag})
      expect(described_class.strong_match?(weak, weak)).to be false
    end

    it 'returns false when the header contains only weak ETags' do
      weak_header = %(W/#{etag})
      expect(described_class.strong_match?(etag, weak_header)).to be false
    end

    it 'matches with wildcard *' do
      expect(described_class.strong_match?(etag, '*')).to be true
    end

    it 'does not match wildcard for weak ETags' do
      weak = %(W/#{etag})
      expect(described_class.strong_match?(weak, '*')).to be false
    end

    it 'matches in a comma-separated list' do
      header = %("aaa", #{etag}, "bbb")
      expect(described_class.strong_match?(etag, header)).to be true
    end

    it 'returns false for nil header' do
      expect(described_class.strong_match?(etag, nil)).to be false
    end
  end

  describe '.modified?' do
    let(:etag) { described_class.generate('hello') }

    it 'returns false when If-None-Match matches (Rack-style header)' do
      headers = { 'HTTP_IF_NONE_MATCH' => etag }
      expect(described_class.modified?(etag, headers)).to be false
    end

    it 'returns false when If-None-Match matches (plain header)' do
      headers = { 'If-None-Match' => etag }
      expect(described_class.modified?(etag, headers)).to be false
    end

    it 'returns true when If-None-Match does not match' do
      headers = { 'HTTP_IF_NONE_MATCH' => '"other"' }
      expect(described_class.modified?(etag, headers)).to be true
    end

    it 'returns true when no If-None-Match header is present' do
      expect(described_class.modified?(etag, {})).to be true
    end
  end

  describe Philiprehberger::Etag::Middleware do
    let(:body_content) { 'Hello, World!' }
    let(:app) { ->(_env) { [200, { 'Content-Type' => 'text/plain' }, [body_content]] } }
    let(:middleware) { described_class.new(app) }

    it 'adds an ETag header to the response' do
      _status, headers, _body = middleware.call({})
      expect(headers['ETag']).to match(/\A"[a-f0-9]{64}"\z/)
    end

    it 'returns 304 when If-None-Match matches' do
      etag = Philiprehberger::Etag.generate(body_content)
      status, _headers, body = middleware.call({ 'HTTP_IF_NONE_MATCH' => etag })
      expect(status).to eq(304)
      expect(body).to eq([])
    end

    it 'returns 200 when If-None-Match does not match' do
      status, _headers, _body = middleware.call({ 'HTTP_IF_NONE_MATCH' => '"stale"' })
      expect(status).to eq(200)
    end

    it 'returns 200 when no If-None-Match header is present' do
      status, _headers, body = middleware.call({})
      expect(status).to eq(200)
      expect(body).to eq([body_content])
    end

    it 'does not add ETag to non-200 responses' do
      error_app = ->(_env) { [404, { 'Content-Type' => 'text/plain' }, ['Not Found']] }
      error_middleware = described_class.new(error_app)
      _status, headers, _body = error_middleware.call({})
      expect(headers).not_to have_key('ETag')
    end

    it 'does not overwrite an existing ETag header' do
      existing_app = ->(_env) { [200, { 'ETag' => '"existing"' }, ['content']] }
      existing_middleware = described_class.new(existing_app)
      _status, headers, _body = existing_middleware.call({})
      expect(headers['ETag']).to eq('"existing"')
    end
  end
end
