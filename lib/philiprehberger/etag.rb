# frozen_string_literal: true

require_relative 'etag/version'
require_relative 'etag/generator'
require_relative 'etag/matcher'
require_relative 'etag/middleware'

module Philiprehberger
  module Etag
    class Error < StandardError; end

    # Generates a strong ETag from content using SHA256.
    #
    # @param content [String] the content to hash
    # @return [String] a quoted ETag string
    def self.generate(content)
      Generator.strong(content)
    end

    # Generates a weak ETag from content using MD5.
    #
    # @param content [String] the content to hash
    # @return [String] a weak ETag string prefixed with W/
    def self.weak(content)
      Generator.weak(content)
    end

    # Evaluates an ETag against an If-None-Match header using weak comparison.
    #
    # @param etag [String] the ETag to compare
    # @param if_none_match_header [String] the If-None-Match header value
    # @return [Boolean] true if the ETag matches
    def self.match?(etag, if_none_match_header)
      Matcher.match?(etag, if_none_match_header)
    end

    # Evaluates an ETag against an If-Match header using strong comparison.
    #
    # @param etag [String] the ETag to compare
    # @param if_match_header [String] the If-Match header value
    # @return [Boolean] true if the ETag strongly matches
    def self.strong_match?(etag, if_match_header)
      Matcher.strong_match?(etag, if_match_header)
    end

    # Checks if a resource has been modified based on request headers.
    #
    # @param etag [String] the current ETag of the resource
    # @param request_headers [Hash] a hash of request headers
    # @return [Boolean] true if the resource has been modified
    def self.modified?(etag, request_headers)
      Matcher.modified?(etag, request_headers)
    end
  end
end
