# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-04-16

### Added
- `Matcher#strong_match?` and `#weak_match?` predicates for distinguishing strong vs. weak RFC 7232 ETag matches

## [0.4.0] - 2026-04-15

### Added
- `Etag.strip_weak(etag)` — returns the ETag value with the `W/` prefix removed (noop if already strong, `nil` passes through, non-String inputs returned unchanged)

## [0.3.0] - 2026-04-15

### Added
- `Etag.equal?(a, b)` — weak comparison of two ETag strings (ignores the W/ prefix)

## [0.2.1] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.2.0] - 2026-03-28

### Added

- Custom hash algorithm support for `Etag.generate` via `algorithm:` keyword (`:sha256`, `:sha512`, `:md5`, `:sha1`)
- If-Modified-Since support with `Etag.modified_since?` and `Etag.not_modified_since?`
- File-based ETag generation with `Etag.for_file` using file mtime and size
- ETag header parsing with `Etag.parse` returning structured hash or array of hashes
- Content-encoding awareness in Middleware (hashes raw body before encoding)
- GitHub issue templates (bug report, feature request)
- Dependabot configuration for bundler and GitHub Actions
- Pull request template

## [0.1.1] - 2026-03-26

### Added

- Add GitHub funding configuration

## [0.1.0] - 2026-03-26

### Added
- Initial release
- Strong ETag generation using SHA256
- Weak ETag generation using MD5
- If-None-Match header evaluation with weak comparison
- If-Match header evaluation with strong comparison
- Modified detection from request headers
- Rack middleware for automatic ETag headers and 304 responses
