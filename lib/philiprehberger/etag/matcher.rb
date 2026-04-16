# frozen_string_literal: true

require_relative 'parser'

module Philiprehberger
  module Etag
    # Evaluates If-None-Match and If-Match headers against ETags.
    #
    # Can be used as a module (class methods) or instantiated with a header
    # to expose the strong/weak predicate helpers.
    class Matcher
      # Performs a weak comparison of an ETag against an If-None-Match header value.
      # Weak comparison ignores the W/ prefix when comparing.
      #
      # @param etag [String] the ETag to compare
      # @param header [String] the If-None-Match header value (may contain multiple ETags)
      # @return [Boolean] true if the ETag matches any value in the header
      def self.match?(etag, header)
        return false if header.nil? || header.empty?
        return true if header.strip == '*'

        normalized = strip_weak(etag)
        parse_etags(header).any? { |candidate| strip_weak(candidate) == normalized }
      end

      # Performs a strong comparison of an ETag against an If-Match header value.
      # Strong comparison requires exact match including the W/ prefix.
      # Weak ETags never match in strong comparison.
      #
      # @param etag [String] the ETag to compare
      # @param header [String] the If-Match header value (may contain multiple ETags)
      # @return [Boolean] true if the ETag strongly matches any value in the header
      def self.strong_match?(etag, header)
        return false if header.nil? || header.empty?
        return false if weak?(etag)
        return true if header.strip == '*'

        parse_etags(header).any? { |candidate| !weak?(candidate) && candidate == etag }
      end

      # Determines whether a resource has been modified based on request headers.
      # Checks the If-None-Match header using weak comparison.
      #
      # @param etag [String] the current ETag of the resource
      # @param request_headers [Hash] a hash of request headers
      # @return [Boolean] true if the resource has been modified (ETag does not match)
      def self.modified?(etag, request_headers)
        if_none_match = request_headers['HTTP_IF_NONE_MATCH'] || request_headers['If-None-Match']
        return true if if_none_match.nil? || if_none_match.empty?

        !match?(etag, if_none_match)
      end

      # Strips the weak validator prefix from an ETag.
      #
      # @param etag [String] the ETag string
      # @return [String] the ETag without the W/ prefix
      def self.strip_weak(etag)
        etag.sub(%r{\AW/}, '')
      end

      # Checks whether an ETag is a weak validator.
      #
      # @param etag [String] the ETag string
      # @return [Boolean] true if the ETag starts with W/
      def self.weak?(etag)
        etag.start_with?('W/')
      end

      # Parses a comma-separated list of ETags from a header value.
      #
      # @param header [String] the header value
      # @return [Array<String>] the individual ETag values
      def self.parse_etags(header)
        header.split(',').map(&:strip).reject(&:empty?)
      end

      private_class_method :strip_weak, :weak?, :parse_etags

      # Builds a Matcher bound to a header value. Instances expose
      # {#strong_match?} and {#weak_match?} predicate helpers for
      # distinguishing the nature of a match per RFC 7232 §2.3.2.
      #
      # @param header [String, nil] the If-Match or If-None-Match header value
      def initialize(header)
        @header = header
        @wildcard = !header.nil? && header.strip == '*'
        @entries = parse_entries(header)
      end

      # Returns true iff any entry in the header is a strong match for the
      # given ETag. Strong comparison requires that the opaque-tag be
      # byte-for-byte equal and that neither side be weak.
      #
      # Wildcard `*` returns true for both predicates — wildcard expresses
      # "any representation" per RFC 7232 §3.1 and is not a weakness signal.
      #
      # @param etag [String] the ETag to compare; accepts raw, quoted, or W/"..." input
      # @return [Boolean]
      def strong_match?(etag)
        return false if etag.nil?
        return true if @wildcard # wildcard matches any representation

        parsed = parse_one(etag)
        return false if parsed[:weak]

        @entries.any? { |entry| !entry[:weak] && entry[:value] == parsed[:value] }
      end

      # Returns true iff any entry in the header has the same opaque-tag as
      # the given ETag, ignoring weakness on either side. This is the weak
      # comparison function per RFC 7232 §2.3.2.
      #
      # Wildcard `*` returns true for both predicates.
      #
      # @param etag [String] the ETag to compare; accepts raw, quoted, or W/"..." input
      # @return [Boolean]
      def weak_match?(etag)
        return false if etag.nil?
        return true if @wildcard # wildcard matches any representation

        parsed = parse_one(etag)
        @entries.any? { |entry| entry[:value] == parsed[:value] }
      end

      private

      def parse_entries(header)
        return [] if header.nil? || header.strip.empty?
        return [] if header.strip == '*'

        result = Parser.parse(header)
        result.is_a?(Array) ? result : [result]
      end

      # Parses a single ETag token (raw `abc`, quoted `"abc"`, or weak `W/"abc"`)
      # into `{ weak:, value: }` using the public parser.
      def parse_one(etag)
        result = Parser.parse(etag.to_s)
        result.is_a?(Array) ? result.first : result
      end
    end
  end
end
