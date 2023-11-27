# frozen_string_literal: true

module XxxRename
  module Data
    # Scene Data parsed from filename. All attributes(except title) are optional.
    # It is up to the site clients to implement what fields they choose to
    # search the site.
    class ParsedSceneData < Base
      attribute? :title, Types::StrippedString.default("__blank__")

      attribute? :female_actors, Types::Array.of(Types::StrippedString).default([].freeze)
      attribute? :male_actors, Types::Array.of(Types::StrippedString).default([].freeze)
      attribute? :actors, Types::Array.of(Types::StrippedString).default([].freeze)
      attribute? :collection, Types::StrippedString.optional
      attribute? :collection_tag, Types::StrippedString.optional
      attribute? :id, Types::StrippedString.optional

      # some filenames may have a scene index number (e.g. s01)
      attribute? :index, Types::StrippedString.optional
      attribute? :date_released, Types::Time.optional

      def blank?
        title == "__blank__" && attributes.except(:title).values.all?(&:blank?)
      end

      def empty?
        title == "__blank__" && attributes.except(:title).values.all?(&:empty?)
      end

      def self.blank_data
        new
      end

      def to_compact_h
        attributes.compact
      end
    end
  end
end
