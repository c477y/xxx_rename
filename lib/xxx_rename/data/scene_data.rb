# frozen_string_literal: true

require "digest/md5"

module XxxRename
  module Data
    class SceneMovieData < Base
      attribute :name, Types::String
      attribute? :date, Types::Time
      attribute? :url, Types::String
      attribute :front_image, Types::String
      attribute? :back_image, Types::String
      attribute? :studio, Types::String
      attribute? :synopsis, Types::String
    end

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
              "$#{actors.join("-").normalize}" \
              ">"
            Digest::MD5.hexdigest(str)
          end
      end
    end
  end
end
