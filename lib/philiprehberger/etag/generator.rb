# frozen_string_literal: true

require 'digest'
require 'openssl'

module Philiprehberger
  module Etag
    # Generates strong and weak ETags from content using cryptographic hashes.
    module Generator
      ALGORITHMS = {
        sha256: Digest::SHA256,
        sha512: Digest::SHA512,
        md5: Digest::MD5,
        sha1: Digest::SHA1
      }.freeze

      # Algorithms that delegate to OpenSSL::Digest rather than the stdlib `digest/*` classes.
      OPENSSL_ALGORITHMS = { sha3_256: 'SHA3-256' }.freeze

      # Generates a strong ETag from content using the specified algorithm.
      #
      # @param content [String] the content to hash
      # @param algorithm [Symbol] the hash algorithm (:sha256, :sha512, :md5, :sha1, :sha3_256)
      # @return [String] a quoted ETag string, e.g. `"\"a1b2c3...\""`
      # @raise [ArgumentError] if the algorithm is not supported
      def self.strong(content, algorithm: :sha256)
        digest = compute_digest(content, algorithm)
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

      # Generates a strong ETag for a file based on its mtime and size.
      # Does not read file content.
      #
      # @param path [String] the file path
      # @param algorithm [Symbol] the hash algorithm (:sha256, :sha512, :md5, :sha1, :sha3_256)
      # @return [String] a quoted ETag string
      # @raise [Errno::ENOENT] if the file does not exist
      # @raise [ArgumentError] if the algorithm is not supported
      def self.for_file(path, algorithm: :sha256)
        stat = File.stat(path)
        fingerprint = "#{stat.mtime.to_i}-#{stat.size}"
        digest = compute_digest(fingerprint, algorithm)
        %("#{digest}")
      end

      # Computes a hex digest of the given content using the specified algorithm.
      #
      # @param content [String] the content to hash
      # @param algorithm [Symbol] the hash algorithm
      # @return [String] the hex digest
      # @raise [ArgumentError] if the algorithm is not supported
      def self.compute_digest(content, algorithm)
        if (openssl_name = OPENSSL_ALGORITHMS[algorithm])
          return OpenSSL::Digest.hexdigest(openssl_name, content.to_s)
        end

        klass = ALGORITHMS[algorithm]
        unless klass
          supported = (ALGORITHMS.keys + OPENSSL_ALGORITHMS.keys).join(', ')
          raise ArgumentError, "unsupported algorithm: #{algorithm}. Supported: #{supported}"
        end

        klass.hexdigest(content.to_s)
      end

      private_class_method :compute_digest
    end
  end
end
