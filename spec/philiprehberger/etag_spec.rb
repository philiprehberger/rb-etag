# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

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

    context 'with custom algorithm' do
      it 'generates with sha256 by default' do
        etag = described_class.generate('hello')
        expect(etag).to match(/\A"[a-f0-9]{64}"\z/)
      end

      it 'generates with sha512' do
        etag = described_class.generate('hello', algorithm: :sha512)
        expect(etag).to match(/\A"[a-f0-9]{128}"\z/)
      end

      it 'generates with md5' do
        etag = described_class.generate('hello', algorithm: :md5)
        expect(etag).to match(/\A"[a-f0-9]{32}"\z/)
      end

      it 'generates with sha1' do
        etag = described_class.generate('hello', algorithm: :sha1)
        expect(etag).to match(/\A"[a-f0-9]{40}"\z/)
      end

      it 'raises ArgumentError for unsupported algorithm' do
        expect { described_class.generate('hello', algorithm: :blake2) }
          .to raise_error(ArgumentError, /unsupported algorithm/)
      end

      it 'returns different results for different algorithms' do
        sha256 = described_class.generate('hello', algorithm: :sha256)
        md5 = described_class.generate('hello', algorithm: :md5)
        expect(sha256).not_to eq(md5)
      end
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

  describe '.equal?' do
    it 'returns true for identical ETags' do
      expect(described_class.equal?('"abc"', '"abc"')).to be true
    end

    it 'treats a weak ETag as equal to its strong counterpart' do
      expect(described_class.equal?('"abc"', 'W/"abc"')).to be true
    end

    it 'returns false for different ETags' do
      expect(described_class.equal?('"abc"', '"def"')).to be false
    end

    it 'returns false when either side is nil' do
      expect(described_class.equal?(nil, '"abc"')).to be false
      expect(described_class.equal?('"abc"', nil)).to be false
    end
  end

  describe '.strip_weak' do
    it 'removes the W/ prefix from a weak ETag' do
      expect(described_class.strip_weak('W/"abc"')).to eq('"abc"')
    end

    it 'returns a strong ETag unchanged' do
      expect(described_class.strip_weak('"abc"')).to eq('"abc"')
    end

    it 'returns nil when given nil' do
      expect(described_class.strip_weak(nil)).to be_nil
    end

    it 'returns non-String inputs unchanged' do
      expect(described_class.strip_weak(42)).to eq(42)
      expect(described_class.strip_weak(:symbol)).to eq(:symbol)
    end

    it 'only strips the leading W/ and leaves the rest of the value intact' do
      expect(described_class.strip_weak('W/"W/abc"')).to eq('"W/abc"')
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

  describe '.for_file' do
    it 'returns a quoted ETag for an existing file' do
      file = Tempfile.new('etag_test')
      file.write('test content')
      file.close

      etag = described_class.for_file(file.path)
      expect(etag).to match(/\A"[a-f0-9]{64}"\z/)
    ensure
      file&.unlink
    end

    it 'returns consistent results for the same file' do
      file = Tempfile.new('etag_test')
      file.write('test content')
      file.close

      etag1 = described_class.for_file(file.path)
      etag2 = described_class.for_file(file.path)
      expect(etag1).to eq(etag2)
    ensure
      file&.unlink
    end

    it 'returns different results when file is modified' do
      file = Tempfile.new('etag_test')
      file.write('original')
      file.close

      etag1 = described_class.for_file(file.path)

      sleep 1.1
      File.write(file.path, 'modified content that is longer')

      etag2 = described_class.for_file(file.path)
      expect(etag1).not_to eq(etag2)
    ensure
      file&.unlink
    end

    it 'supports custom algorithms' do
      file = Tempfile.new('etag_test')
      file.write('test')
      file.close

      etag = described_class.for_file(file.path, algorithm: :md5)
      expect(etag).to match(/\A"[a-f0-9]{32}"\z/)
    ensure
      file&.unlink
    end

    it 'raises Errno::ENOENT for missing files' do
      expect { described_class.for_file('/nonexistent/path/file.txt') }
        .to raise_error(Errno::ENOENT)
    end

    it 'does not read file content' do
      file = Tempfile.new('etag_test')
      file.write('test content')
      file.close

      allow(File).to receive(:read).and_call_original
      described_class.for_file(file.path)
      expect(File).not_to have_received(:read)
    ensure
      file&.unlink
    end
  end

  describe '.parse' do
    it 'parses a strong ETag' do
      result = described_class.parse('"abc123"')
      expect(result).to eq({ weak: false, value: 'abc123' })
    end

    it 'parses a weak ETag' do
      result = described_class.parse('W/"abc123"')
      expect(result).to eq({ weak: true, value: 'abc123' })
    end

    it 'parses multiple ETags into an array' do
      result = described_class.parse('"aaa", W/"bbb", "ccc"')
      expect(result).to eq([
                             { weak: false, value: 'aaa' },
                             { weak: true, value: 'bbb' },
                             { weak: false, value: 'ccc' }
                           ])
    end

    it 'handles a single ETag returning a hash' do
      result = described_class.parse('"single"')
      expect(result).to be_a(Hash)
      expect(result[:value]).to eq('single')
    end

    it 'handles nil header' do
      result = described_class.parse(nil)
      expect(result).to eq({ weak: false, value: '' })
    end

    it 'handles empty header' do
      result = described_class.parse('')
      expect(result).to eq({ weak: false, value: '' })
    end

    it 'handles whitespace-only header' do
      result = described_class.parse('   ')
      expect(result).to eq({ weak: false, value: '' })
    end

    it 'handles ETags with extra whitespace' do
      result = described_class.parse('  "abc"  ,  W/"def"  ')
      expect(result).to eq([
                             { weak: false, value: 'abc' },
                             { weak: true, value: 'def' }
                           ])
    end

    it 'handles unquoted values' do
      result = described_class.parse('abc123')
      expect(result).to eq({ weak: false, value: 'abc123' })
    end
  end

  describe '.modified_since?' do
    let(:last_modified) { Time.utc(2026, 3, 28, 12, 0, 0) }

    it 'returns true when the resource was modified after the header date' do
      header = 'Fri, 27 Mar 2026 12:00:00 GMT'
      expect(described_class.modified_since?(last_modified, header)).to be true
    end

    it 'returns false when the resource was not modified after the header date' do
      header = 'Sun, 29 Mar 2026 12:00:00 GMT'
      expect(described_class.modified_since?(last_modified, header)).to be false
    end

    it 'returns false when times are equal' do
      header = 'Sat, 28 Mar 2026 12:00:00 GMT'
      expect(described_class.modified_since?(last_modified, header)).to be false
    end

    it 'returns true for nil header' do
      expect(described_class.modified_since?(last_modified, nil)).to be true
    end

    it 'returns true for empty header' do
      expect(described_class.modified_since?(last_modified, '')).to be true
    end

    it 'returns true for unparseable header' do
      expect(described_class.modified_since?(last_modified, 'not-a-date')).to be true
    end
  end

  describe '.not_modified_since?' do
    let(:last_modified) { Time.utc(2026, 3, 28, 12, 0, 0) }

    it 'returns false when the resource was modified after the header date' do
      header = 'Fri, 27 Mar 2026 12:00:00 GMT'
      expect(described_class.not_modified_since?(last_modified, header)).to be false
    end

    it 'returns true when the resource was not modified after the header date' do
      header = 'Sun, 29 Mar 2026 12:00:00 GMT'
      expect(described_class.not_modified_since?(last_modified, header)).to be true
    end

    it 'is the inverse of modified_since?' do
      header = 'Fri, 27 Mar 2026 12:00:00 GMT'
      expect(described_class.not_modified_since?(last_modified, header))
        .to eq(!described_class.modified_since?(last_modified, header))
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

    it 'hashes the raw body before Content-Encoding' do
      encoded_app = lambda { |_env|
        [200, { 'Content-Type' => 'text/plain', 'Content-Encoding' => 'gzip' }, ['raw body']]
      }
      encoded_middleware = described_class.new(encoded_app)
      _status, headers, _body = encoded_middleware.call({})

      expected_etag = Philiprehberger::Etag.generate('raw body')
      expect(headers['ETag']).to eq(expected_etag)
    end
  end

  describe Philiprehberger::Etag::Generator do
    describe '.strong' do
      it 'supports sha256 algorithm' do
        etag = described_class.strong('test', algorithm: :sha256)
        expect(etag).to match(/\A"[a-f0-9]{64}"\z/)
      end

      it 'supports sha512 algorithm' do
        etag = described_class.strong('test', algorithm: :sha512)
        expect(etag).to match(/\A"[a-f0-9]{128}"\z/)
      end

      it 'supports md5 algorithm' do
        etag = described_class.strong('test', algorithm: :md5)
        expect(etag).to match(/\A"[a-f0-9]{32}"\z/)
      end

      it 'supports sha1 algorithm' do
        etag = described_class.strong('test', algorithm: :sha1)
        expect(etag).to match(/\A"[a-f0-9]{40}"\z/)
      end

      it 'raises for unsupported algorithm' do
        expect { described_class.strong('test', algorithm: :blake2) }
          .to raise_error(ArgumentError, /unsupported algorithm: blake2/)
      end
    end

    describe '.for_file' do
      it 'generates an ETag from file metadata' do
        file = Tempfile.new('gen_test')
        file.write('content')
        file.close

        etag = described_class.for_file(file.path)
        expect(etag).to match(/\A"[a-f0-9]{64}"\z/)
      ensure
        file&.unlink
      end

      it 'accepts a custom algorithm' do
        file = Tempfile.new('gen_test')
        file.write('content')
        file.close

        etag = described_class.for_file(file.path, algorithm: :sha512)
        expect(etag).to match(/\A"[a-f0-9]{128}"\z/)
      ensure
        file&.unlink
      end
    end
  end

  describe Philiprehberger::Etag::Conditional do
    describe '.modified_since?' do
      let(:last_modified) { Time.utc(2026, 3, 28, 12, 0, 0) }

      it 'returns true when resource is newer' do
        header = 'Fri, 27 Mar 2026 12:00:00 GMT'
        expect(described_class.modified_since?(last_modified, header)).to be true
      end

      it 'returns false when resource is older' do
        header = 'Sun, 29 Mar 2026 12:00:00 GMT'
        expect(described_class.modified_since?(last_modified, header)).to be false
      end

      it 'handles RFC 2822 date format' do
        header = 'Fri, 27 Mar 2026 12:00:00 +0000'
        expect(described_class.modified_since?(last_modified, header)).to be true
      end
    end

    describe '.not_modified_since?' do
      it 'returns the inverse of modified_since?' do
        last_modified = Time.utc(2026, 3, 28, 12, 0, 0)
        header = 'Fri, 27 Mar 2026 12:00:00 GMT'
        expect(described_class.not_modified_since?(last_modified, header)).to be false
      end
    end
  end

  describe Philiprehberger::Etag::Parser do
    describe '.parse' do
      it 'parses a single strong ETag' do
        result = described_class.parse('"abc"')
        expect(result).to eq({ weak: false, value: 'abc' })
      end

      it 'parses a single weak ETag' do
        result = described_class.parse('W/"abc"')
        expect(result).to eq({ weak: true, value: 'abc' })
      end

      it 'parses multiple ETags' do
        result = described_class.parse('"a", "b", "c"')
        expect(result.length).to eq(3)
        expect(result.map { |r| r[:value] }).to eq(%w[a b c])
      end

      it 'parses mixed strong and weak ETags' do
        result = described_class.parse('"strong", W/"weak"')
        expect(result).to eq([
                               { weak: false, value: 'strong' },
                               { weak: true, value: 'weak' }
                             ])
      end

      it 'returns a hash for a single ETag' do
        result = described_class.parse('"only"')
        expect(result).to be_a(Hash)
      end

      it 'returns an array for multiple ETags' do
        result = described_class.parse('"a", "b"')
        expect(result).to be_an(Array)
      end
    end
  end
end
