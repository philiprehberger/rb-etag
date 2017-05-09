# frozen_string_literal: true

module Philiprehberger
  module Etag
    # Parses ETag header values into structured data.
    module Parser
      # Parses an ETag header value into a hash or array of hashes.
      # Handles single ETags, comma-separated lists, weak validators, and quoted strings.
      #
      # @param header [String] the ETag header value
      # @return [Hash, Array<Hash>] a hash with :weak and :value keys, or an array of such hashes
      #   for multi-value headers
      def self.parse(header)
        return { weak: false, value: '' } if header.nil? || header.strip.empty?

        etags = split_etags(header)
        parsed = etags.map { |raw| parse_single(raw) }

        parsed.length == 1 ? parsed.first : parsed
      end

      # Parses a single ETag string into a structured hash.
      #
      # @param raw [String] a single ETag value
      # @return [Hash] a hash with :weak (Boolean) and :value (String) keys
      def self.parse_single(raw)
        trimmed = raw.strip
        weak = trimmed.start_with?('W/')
        value = weak ? trimmed[2..] : trimmed
        value = value[1..-2] if value.start_with?('"') && value.end_with?('"')

        { weak: weak, value: value }
      end

      # Splits a comma-separated ETag header into individual ETag strings.
      # Handles quoted strings that may contain commas.
      #
      # @param header [String] the header value
      # @return [Array<String>] the individual ETag values
      def self.split_etags(header)
        results = []
        current = +''
        in_quotes = false

        header.each_char do |char|
          if char == '"'
            in_quotes = !in_quotes
            current << char
          elsif char == ',' && !in_quotes
            results << current.strip unless current.strip.empty?
            current = +''
          else
            current << char
          end
        end

        results << current.strip unless current.strip.empty?
        results
      end

      private_class_method :parse_single, :split_etags
    end
  end
end
