# frozen_string_literal: true

require 'time'

module Philiprehberger
  module Etag
    # Evaluates If-Modified-Since conditional requests based on timestamps.
    module Conditional
      # Checks if a resource has been modified since the given If-Modified-Since header value.
      # Compares the resource's last modified time against the header's parsed date.
      #
      # @param last_modified [Time] the last modification time of the resource
      # @param if_modified_since_header [String] the If-Modified-Since header value (RFC 2822)
      # @return [Boolean] true if the resource has been modified since the header date
      def self.modified_since?(last_modified, if_modified_since_header)
        return true if if_modified_since_header.nil? || if_modified_since_header.strip.empty?

        header_time = parse_time(if_modified_since_header)
        return true if header_time.nil?

        last_modified.to_i > header_time.to_i
      end

      # Checks if a resource has NOT been modified since the given If-Modified-Since header value.
      # Convenience inverse of {.modified_since?}.
      #
      # @param last_modified [Time] the last modification time of the resource
      # @param if_modified_since_header [String] the If-Modified-Since header value (RFC 2822)
      # @return [Boolean] true if the resource has NOT been modified since the header date
      def self.not_modified_since?(last_modified, if_modified_since_header)
        !modified_since?(last_modified, if_modified_since_header)
      end

      # Parses a time string from an HTTP header. Supports RFC 2822, RFC 2616, and ISO 8601 formats.
      #
      # @param header [String] the time string
      # @return [Time, nil] the parsed time, or nil if parsing fails
      def self.parse_time(header)
        Time.httpdate(header.strip)
      rescue ArgumentError
        begin
          Time.rfc2822(header.strip)
        rescue ArgumentError
          nil
        end
      end

      private_class_method :parse_time
    end
  end
end
