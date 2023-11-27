# frozen_string_literal: true

require "digest/md5"

module XxxRename
  module Data
    class SceneData < Base
      attribute :female_actors, Types::Array.of(Types::String).default([].freeze)
      attribute :male_actors, Types::Array.of(Types::String).default([].freeze)
      attribute :actors, Types::Array.of(Types::String).default([].freeze)
      attribute :collection, Types::String.default("")
      attribute :collection_tag, Types::String.default("")
      attribute :title, Types::String.default("")

      attribute? :id, Types::Coercible::String
      attribute? :date_released, Types::Time
      attribute? :director, Types::String
      attribute? :description, Types::String
      attribute? :scene_link, Types::String
      attribute? :scene_cover, Types::String
      attribute? :movie, SceneMovieData

      def yyyy_mm_dd
        return unless date_released

        date_released&.strftime("%Y_%m_%d")
      end

      def day
        return unless date_released

        d = date_released&.day.to_s
        return if d.empty?

        d.length == 1 ? "0#{d}" : d
      end
      alias dd day

      def month
        return unless date_released

        m = date_released&.month.to_s
        return if m.empty?

        m.length == 1 ? "0#{m}" : m
      end
      alias mm month

      def year
        return unless date_released

        date_released&.year&.to_s
      end
      alias yyyy year

      #
      # Takes a scene information and uses as much information
      # as possible to generate a unique key to minimize the
      # chances of key collision
      #
      # @return [String]
      def key
        @key ||=
          begin
            str = "<#{title.normalize}" \
              "$#{collection.to_s.normalize}" \
              "$#{actors.sort.join("-").normalize}" \
              ">"
            Digest::MD5.hexdigest(str)
          end
      end

      def to_compact_h
        attributes.compact
      end

      #
      # Helper method to check if the scene data matches a given scene data
      # The match happens by checking the title, collection, actors and date_released
      # If either attributes have nil values, then they are not considered for matching
      #
      # @param [SceneData] other
      # @return [Boolean]
      def match?(other) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        raise ArgumentError, "expected other to respond to .to_h" unless other.respond_to?(:to_h)

        other = other.to_h.with_indifferent_access.compact

        required_keys = %w[title actors]
        unless other.to_h.slice(*required_keys).keys.sort == required_keys.sort
          raise ArgumentError, "expected other to define title, collection and actors"
        end

        other_sd = other.is_a?(SceneData) ? other : SceneData.new(other.to_h)

        resp = {}
        resp[:title] = title.n_substring_either?(other_sd.title) if title.present? && other_sd.title.present?

        # collection match can cause false-negatives
        # resp[:collection] = collection.n_substring_either?(other_sd.collection) if collection.present? && other_sd.collection.present?

        if actors.present? && other_sd.actors.present?
          self_n_actors = actors.map(&:normalize)
          other_n_actors = other_sd.actors.map(&:normalize)
          resp[:actors] = (self_n_actors & other_n_actors).any?
        end

        if date_released.present? && other_sd.date_released.present?
          resp[:date_released] = (date_released.year == other_sd.date_released.year) &&
                                 (date_released.month == other_sd.date_released.month) &&
                                 (date_released.day == other_sd.date_released.day)
        end
        XxxRename.logger.debug "[MATCH RESULT] #{to_compact_h} vs #{other_sd.to_compact_h} => #{resp}"
        XxxRename.logger.ap resp, :debug

        resp.values.all?
      end
    end
  end
end
