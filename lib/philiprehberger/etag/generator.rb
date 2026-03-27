# frozen_string_literal: true

require 'digest'

module Philiprehberger
  module Etag
    # Generates strong and weak ETags from content using cryptographic hashes.
    module Generator
      # Generates a strong ETag from content using SHA256.
      #
      # @param content [String] the content to hash
      # @return [String] a quoted ETag string, e.g. `"\"a1b2c3...\""`
      def self.strong(content)
        digest = Digest::SHA256.hexdigest(content.to_s)
        %("#{digest}")
      end

      # Generates a weak ETag from content using MD5.
      #
      # @param content [String] the content to hash
      # @return [String] a weak ETag string, e.g. `"W/\"a1b2c3...\""`
      def self.weak(content)
        digest = Digest::MD5.hexdigest(content.to_s)
        %(W/"#{digest}")
      end
    end
  end
end
