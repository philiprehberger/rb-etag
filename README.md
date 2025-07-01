# philiprehberger-etag

[![Tests](https://github.com/philiprehberger/rb-etag/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-etag/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-etag.svg)](https://rubygems.org/gems/philiprehberger-etag)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-etag)](https://github.com/philiprehberger/rb-etag/commits/main)

ETag generation and conditional request helpers with Rack middleware

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-etag"
```

Or install directly:

```bash
gem install philiprehberger-etag
```

## Usage

```ruby
require "philiprehberger/etag"

etag = Philiprehberger::Etag.generate("Hello, World!")
# => "\"dffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f\""
```

### Custom Hash Algorithm

```ruby
require "philiprehberger/etag"

Philiprehberger::Etag.generate("content", algorithm: :sha256)  # default
Philiprehberger::Etag.generate("content", algorithm: :sha512)
Philiprehberger::Etag.generate("content", algorithm: :md5)
Philiprehberger::Etag.generate("content", algorithm: :sha1)
```

### Weak ETags

```ruby
require "philiprehberger/etag"

weak = Philiprehberger::Etag.weak("Hello, World!")
# => "W/\"65a8e27d8879283831b664bd8b7f0ad4\""
```

### Conditional Request Matching

```ruby
require "philiprehberger/etag"

etag = Philiprehberger::Etag.generate("content")

# Weak comparison (If-None-Match)
Philiprehberger::Etag.match?(etag, etag)           # => true
Philiprehberger::Etag.match?(etag, "*")             # => true
Philiprehberger::Etag.match?(etag, "\"other\"")     # => false

# Strong comparison (If-Match)
Philiprehberger::Etag.strong_match?(etag, etag)     # => true
```

### Direct Comparison

Compare two ETag strings using weak semantics (the `W/` prefix is ignored):

```ruby
Philiprehberger::Etag.equal?('"abc"', 'W/"abc"')  # => true
Philiprehberger::Etag.equal?('"abc"', '"def"')     # => false
```

### Strip Weak Prefix

Remove the `W/` weak validator prefix from an ETag (noop if it is already strong):

```ruby
Philiprehberger::Etag.strip_weak('W/"abc"')  # => "\"abc\""
Philiprehberger::Etag.strip_weak('"abc"')     # => "\"abc\""
Philiprehberger::Etag.strip_weak(nil)         # => nil
```

### Strong vs. Weak Match Predicates

Build a `Matcher` bound to a header value to distinguish strong from weak matches per RFC 7232:

```ruby
require "philiprehberger/etag"

matcher = Philiprehberger::Etag::Matcher.new('"abc"')
matcher.strong_match?('"abc"')    # => true
matcher.weak_match?('W/"abc"')    # => true (same opaque tag, weakness ignored)
matcher.strong_match?('W/"abc"')  # => false (weak not allowed in strong comparison)

wildcard = Philiprehberger::Etag::Matcher.new('*')
wildcard.strong_match?('"abc"')   # => true
wildcard.weak_match?('W/"abc"')   # => true
```

### Modified Detection

```ruby
require "philiprehberger/etag"

etag = Philiprehberger::Etag.generate("content")

headers = { "HTTP_IF_NONE_MATCH" => etag }
Philiprehberger::Etag.modified?(etag, headers)  # => false

headers = { "HTTP_IF_NONE_MATCH" => "\"stale\"" }
Philiprehberger::Etag.modified?(etag, headers)  # => true
```

### If-Modified-Since Support

```ruby
require "philiprehberger/etag"

last_modified = Time.utc(2026, 3, 28, 12, 0, 0)

Philiprehberger::Etag.modified_since?(last_modified, "Fri, 27 Mar 2026 12:00:00 GMT")
# => true (resource is newer)

Philiprehberger::Etag.not_modified_since?(last_modified, "Sun, 29 Mar 2026 12:00:00 GMT")
# => true (resource is older)
```

### File-Based ETags

```ruby
require "philiprehberger/etag"

etag = Philiprehberger::Etag.for_file("/path/to/file.txt")
# => "\"a1b2c3...\"" (based on mtime + size, does not read content)

etag = Philiprehberger::Etag.for_file("/path/to/file.txt", algorithm: :md5)
```

### ETag Parsing

```ruby
require "philiprehberger/etag"

Philiprehberger::Etag.parse('"abc123"')
# => { weak: false, value: "abc123" }

Philiprehberger::Etag.parse('W/"abc123"')
# => { weak: true, value: "abc123" }

Philiprehberger::Etag.parse('"aaa", W/"bbb", "ccc"')
# => [{ weak: false, value: "aaa" }, { weak: true, value: "bbb" }, { weak: false, value: "ccc" }]
```

### Rack Middleware

```ruby
# config.ru
require "philiprehberger/etag"

use Philiprehberger::Etag::Middleware

run MyApp
```

The middleware computes a strong ETag from the raw response body before any Content-Encoding is applied, adds the `ETag` header, and returns `304 Not Modified` with an empty body when `If-None-Match` matches.

## API

| Method | Description |
|--------|-------------|
| `Etag.generate(content, algorithm: :sha256)` | Strong ETag using specified algorithm, returns quoted string |
| `Etag.weak(content)` | Weak ETag from MD5, returns `W/"..."` string |
| `Etag.match?(etag, header)` | Weak comparison against If-None-Match header |
| `Etag.equal?(a, b)` | Compare two ETag strings with weak semantics (strips W/) |
| `Etag.strip_weak(etag)` | Return the ETag with the `W/` prefix removed; `nil` passes through, non-Strings returned unchanged |
| `Etag.strong_match?(etag, header)` | Strong comparison against If-Match header |
| `Etag.modified?(etag, request_headers)` | Check if resource is modified based on ETag headers |
| `Etag.modified_since?(last_modified, header)` | Check if resource was modified after If-Modified-Since date |
| `Etag.not_modified_since?(last_modified, header)` | Inverse of `modified_since?` |
| `Etag.for_file(path, algorithm: :sha256)` | Strong ETag from file mtime and size without reading content |
| `Etag.parse(header)` | Parse ETag header into `{weak:, value:}` hash or array of hashes |
| `Etag::Matcher.new(header).strong_match?(etag)` | True iff header has a strong match for etag (byte-equal opaque tag, neither side weak); wildcard returns true |
| `Etag::Matcher.new(header).weak_match?(etag)` | True iff header has an entry with the same opaque tag as etag (weakness ignored); wildcard returns true |
| `Etag::Middleware.new(app)` | Rack middleware for automatic ETag and 304 handling |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-etag)

🐛 [Report issues](https://github.com/philiprehberger/rb-etag/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-etag/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
