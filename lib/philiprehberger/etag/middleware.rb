# frozen_string_literal: true

module Philiprehberger
  module Etag
    # Rack middleware that automatically adds ETag headers to responses
    # and returns 304 Not Modified when the client's cached version matches.
    # The ETag is computed from the raw response body before any Content-Encoding
    # is applied, ensuring consistent hashing regardless of compression.
    class Middleware
      # @param app [#call] the Rack application
      def initialize(app)
        @app = app
      end

      # Processes a Rack request. Computes an ETag from the response body,
      # adds the ETag header, and returns 304 if If-None-Match matches.
      #
      # @param env [Hash] the Rack environment
      # @return [Array] a Rack response triplet [status, headers, body]
      def call(env)
        status, headers, body = @app.call(env)

        return [status, headers, body] unless etag_eligible?(status, headers)

        response_body = extract_body(body)
        etag = Generator.strong(response_body)
        headers['ETag'] = etag

        if_none_match = env['HTTP_IF_NONE_MATCH']
        if if_none_match && Matcher.match?(etag, if_none_match)
          body.close if body.respond_to?(:close)
          [304, headers, []]
        else
          [status, headers, body]
        end
      end

      private

      # Determines whether a response is eligible for ETag generation.
      # Only 200 OK responses without an existing ETag are processed.
      #
      # @param status [Integer] the HTTP status code
      # @param headers [Hash] the response headers
      # @return [Boolean]
      def etag_eligible?(status, headers)
        status == 200 && !headers.key?('ETag')
      end

      # Extracts the full response body as a string.
      # This reads the raw body before any Content-Encoding is applied.
      #
      # @param body [#each] the Rack response body
      # @return [String] the concatenated body
      def extract_body(body)
        parts = body.map { |part| part }
        parts.join
      end
    end
  end
end
