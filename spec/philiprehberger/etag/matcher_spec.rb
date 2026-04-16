# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::Etag::Matcher do
  describe 'predicate helpers' do
    describe '#strong_match?' do
      it 'returns true for an exact strong match' do
        matcher = described_class.new('"abc"')
        expect(matcher.strong_match?('"abc"')).to be true
      end

      it 'returns false when header is strong but the given etag is weak' do
        matcher = described_class.new('"abc"')
        expect(matcher.strong_match?('W/"abc"')).to be false
      end

      it 'returns false when header entry is weak but the given etag is strong' do
        matcher = described_class.new('W/"abc"')
        expect(matcher.strong_match?('"abc"')).to be false
      end

      it 'returns false for weak-vs-weak with the same opaque tag' do
        matcher = described_class.new('W/"abc"')
        expect(matcher.strong_match?('W/"abc"')).to be false
      end

      it 'returns false for a different opaque tag' do
        matcher = described_class.new('"abc"')
        expect(matcher.strong_match?('"def"')).to be false
      end

      it 'returns true for wildcard regardless of weakness' do
        matcher = described_class.new('*')
        expect(matcher.strong_match?('"abc"')).to be true
        expect(matcher.strong_match?('W/"abc"')).to be true
      end

      it 'accepts raw unquoted input' do
        matcher = described_class.new('"abc"')
        expect(matcher.strong_match?('abc')).to be true
      end

      it 'accepts quoted input' do
        matcher = described_class.new('abc')
        expect(matcher.strong_match?('"abc"')).to be true
      end

      it 'finds a strong entry within a comma-separated header' do
        matcher = described_class.new('W/"aaa", "bbb", "ccc"')
        expect(matcher.strong_match?('"bbb"')).to be true
        expect(matcher.strong_match?('"aaa"')).to be false
      end

      it 'returns false for nil input' do
        matcher = described_class.new('"abc"')
        expect(matcher.strong_match?(nil)).to be false
      end

      it 'returns false for an empty header' do
        matcher = described_class.new('')
        expect(matcher.strong_match?('"abc"')).to be false
      end
    end

    describe '#weak_match?' do
      it 'returns true for weak-vs-strong with the same opaque tag' do
        matcher = described_class.new('"abc"')
        expect(matcher.weak_match?('W/"abc"')).to be true
      end

      it 'returns true for strong-vs-weak with the same opaque tag' do
        matcher = described_class.new('W/"abc"')
        expect(matcher.weak_match?('"abc"')).to be true
      end

      it 'returns true for weak-vs-weak with the same opaque tag' do
        matcher = described_class.new('W/"abc"')
        expect(matcher.weak_match?('W/"abc"')).to be true
      end

      it 'returns true for an exact strong match' do
        matcher = described_class.new('"abc"')
        expect(matcher.weak_match?('"abc"')).to be true
      end

      it 'returns false for a different opaque tag' do
        matcher = described_class.new('"abc"')
        expect(matcher.weak_match?('"def"')).to be false
      end

      it 'returns true for wildcard regardless of weakness' do
        matcher = described_class.new('*')
        expect(matcher.weak_match?('"abc"')).to be true
        expect(matcher.weak_match?('W/"abc"')).to be true
      end

      it 'accepts raw unquoted input' do
        matcher = described_class.new('"abc"')
        expect(matcher.weak_match?('abc')).to be true
      end

      it 'accepts quoted input' do
        matcher = described_class.new('abc')
        expect(matcher.weak_match?('"abc"')).to be true
      end

      it 'finds any matching entry within a comma-separated header' do
        matcher = described_class.new('"aaa", W/"bbb", "ccc"')
        expect(matcher.weak_match?('W/"aaa"')).to be true
        expect(matcher.weak_match?('"bbb"')).to be true
        expect(matcher.weak_match?('"ddd"')).to be false
      end

      it 'returns false for nil input' do
        matcher = described_class.new('"abc"')
        expect(matcher.weak_match?(nil)).to be false
      end

      it 'returns false for an empty header' do
        matcher = described_class.new('')
        expect(matcher.weak_match?('"abc"')).to be false
      end
    end

    describe 'strong vs. weak distinction' do
      it 'strong_match? is false and weak_match? is true for weak-vs-strong same opaque tag' do
        matcher = described_class.new('"abc"')
        expect(matcher.strong_match?('W/"abc"')).to be false
        expect(matcher.weak_match?('W/"abc"')).to be true
      end

      it 'both are false for different opaque tags' do
        matcher = described_class.new('"abc"')
        expect(matcher.strong_match?('"xyz"')).to be false
        expect(matcher.weak_match?('"xyz"')).to be false
      end

      it 'both are true for wildcard' do
        matcher = described_class.new('*')
        expect(matcher.strong_match?('"abc"')).to be true
        expect(matcher.weak_match?('"abc"')).to be true
      end
    end
  end
end
