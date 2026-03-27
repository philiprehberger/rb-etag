# frozen_string_literal: true

module Philiprehberger
  module Etag
    # Evaluates If-None-Match and If-Match headers against ETags.
    module Matcher
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
    end
  end
end
