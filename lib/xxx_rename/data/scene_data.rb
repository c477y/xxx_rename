# frozen_string_literal: true

require "digest/md5"

module XxxRename
  module Data
    class SceneData < Base
      attribute :female_actors, Types::Array.of(Types::String).default([].freeze)
      attribute :male_actors, Types::Array.of(Types::String).default([].freeze)
      attribute :actors, Types::Array.of(Types::String)
      attribute :collection, Types::String.default("")
      attribute :collection_tag, Types::String.default("")
      attribute :title, Types::String
      attribute? :description, Types::String
      attribute? :id, Types::Coercible::String.optional
      attribute? :date_released, Types::Time.optional
      attribute :scene_link, Types::String.default("")
      attribute :original_filenames, Types::Set.default(Set.new.freeze)
      attribute? :movie do
        attribute :name, Types::String
        attribute? :date, Types::Time
        attribute? :url, Types::String
        attribute :front_image, Types::String
        attribute? :back_image, Types::String
        attribute? :studio, Types::String
        attribute? :synopsis, Types::String
      end

      def yyyy_mm_dd
        date_released&.strftime("%Y_%m_%d")
      end

      def day
        d = date_released&.day.to_s
        return if d.empty?

        d.length == 1 ? "0#{d}" : d
      end
      alias dd day

      def month
        m = date_released&.month.to_s
        return if m.empty?

        m.length == 1 ? "0#{m}" : m
      end
      alias mm month

      def year
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
