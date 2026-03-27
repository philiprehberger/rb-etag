# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-03-26

### Added
- Initial release
- Strong ETag generation using SHA256
- Weak ETag generation using MD5
- If-None-Match header evaluation with weak comparison
- If-Match header evaluation with strong comparison
- Modified detection from request headers
- Rack middleware for automatic ETag headers and 304 responses
