# frozen_string_literal: true

require_relative 'etag/version'
require_relative 'etag/generator'
require_relative 'etag/matcher'
require_relative 'etag/middleware'
require_relative 'etag/parser'
require_relative 'etag/conditional'

module Philiprehberger
  module Etag
    class Error < StandardError; end

    # Generates a strong ETag from content using the specified algorithm.
    #
    # @param content [String] the content to hash
    # @param algorithm [Symbol] the hash algorithm (:sha256, :sha512, :md5, :sha1, :sha3_256)
    # @return [String] a quoted ETag string
    # @raise [ArgumentError] if the algorithm is not supported
    def self.generate(content, algorithm: :sha256)
      Generator.strong(content, algorithm: algorithm)
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

    # Generates a strong ETag for a file based on its mtime and size.
    # Does not read file content.
    #
    # @param path [String] the file path
    # @param algorithm [Symbol] the hash algorithm (:sha256, :sha512, :md5, :sha1, :sha3_256)
    # @return [String] a quoted ETag string
    # @raise [Errno::ENOENT] if the file does not exist
    # @raise [ArgumentError] if the algorithm is not supported
    def self.for_file(path, algorithm: :sha256)
      Generator.for_file(path, algorithm: algorithm)
    end

    # Parses an ETag header value into a structured hash or array of hashes.
    #
    # @param header [String] the ETag header value
    # @return [Hash, Array<Hash>] a hash with :weak and :value keys, or array of such hashes
    def self.parse(header)
      Parser.parse(header)
    end

    # Checks if a resource has been modified since the given If-Modified-Since header value.
    #
    # @param last_modified [Time] the last modification time of the resource
    # @param if_modified_since_header [String] the If-Modified-Since header value (RFC 2822)
    # @return [Boolean] true if the resource has been modified since the header date
    def self.modified_since?(last_modified, if_modified_since_header)
      Conditional.modified_since?(last_modified, if_modified_since_header)
    end

    # Compare two ETag strings using weak comparison semantics (W/ prefix is ignored).
    #
    # @param a [String] first ETag string
    # @param b [String] second ETag string
    # @return [Boolean] true if the two ETags represent the same validator
    def self.equal?(a, b)
      return false if a.nil? || b.nil?

      a.sub(%r{\AW/}, '') == b.sub(%r{\AW/}, '')
    end

    # Tests whether an ETag value is a weak validator.
    #
    # Returns true when the value is a String that starts with the literal
    # `W/` prefix per RFC 7232 (uppercase W). Returns false for strong ETags,
    # nil, and non-String inputs.
    #
    # @param etag [String, nil] the ETag value
    # @return [Boolean]
    def self.weak?(etag)
      return false unless etag.is_a?(String)

      etag.start_with?('W/')
    end

    # Strips the weak validator prefix (W/) from an ETag string.
    # Returns the input unchanged if it is not a String or does not start with W/.
    #
    # @param etag [String, nil] the ETag string
    # @return [String, nil] the ETag without the W/ prefix, or the input unchanged
    def self.strip_weak(etag)
      return nil if etag.nil?
      return etag unless etag.is_a?(String)

      etag.sub(%r{\AW/}, '')
    end

    # Checks if a resource has NOT been modified since the given If-Modified-Since header value.
    #
    # @param last_modified [Time] the last modification time of the resource
    # @param if_modified_since_header [String] the If-Modified-Since header value (RFC 2822)
    # @return [Boolean] true if the resource has NOT been modified since the header date
    def self.not_modified_since?(last_modified, if_modified_since_header)
      Conditional.not_modified_since?(last_modified, if_modified_since_header)
    end
  end
end
