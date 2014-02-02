# philiprehberger-etag

[![Tests](https://github.com/philiprehberger/rb-etag/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-etag/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-etag.svg)](https://rubygems.org/gems/philiprehberger-etag)
[![License](https://img.shields.io/github/license/philiprehberger/rb-etag)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

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

### Weak ETags

```ruby
weak = Philiprehberger::Etag.weak("Hello, World!")
# => "W/\"65a8e27d8879283831b664bd8b7f0ad4\""
```

### Conditional Request Matching

```ruby
etag = Philiprehberger::Etag.generate("content")

# Weak comparison (If-None-Match)
Philiprehberger::Etag.match?(etag, etag)           # => true
Philiprehberger::Etag.match?(etag, "*")             # => true
Philiprehberger::Etag.match?(etag, "\"other\"")     # => false

# Strong comparison (If-Match)
Philiprehberger::Etag.strong_match?(etag, etag)     # => true
```

### Modified Detection

```ruby
etag = Philiprehberger::Etag.generate("content")

headers = { "HTTP_IF_NONE_MATCH" => etag }
Philiprehberger::Etag.modified?(etag, headers)  # => false

headers = { "HTTP_IF_NONE_MATCH" => "\"stale\"" }
Philiprehberger::Etag.modified?(etag, headers)  # => true
```

### Rack Middleware

```ruby
# config.ru
require "philiprehberger/etag"

use Philiprehberger::Etag::Middleware

run MyApp
```

The middleware computes a strong ETag from the response body, adds the `ETag` header, and returns `304 Not Modified` with an empty body when `If-None-Match` matches.

## API

| Method | Description |
|--------|-------------|
| `Etag.generate(content)` | Strong ETag from SHA256, returns quoted string |
| `Etag.weak(content)` | Weak ETag from MD5, returns `W/"..."` string |
| `Etag.match?(etag, header)` | Weak comparison against If-None-Match header |
| `Etag.strong_match?(etag, header)` | Strong comparison against If-Match header |
| `Etag.modified?(etag, request_headers)` | Check if resource is modified based on headers |
| `Etag::Middleware.new(app)` | Rack middleware for automatic ETag and 304 handling |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

[MIT](LICENSE)
