# frozen_string_literal: true

require "active_support/core_ext/object/blank"

module XxxRename
  module Data
    class StashPerformerData < Base
      attribute :name, Types::String
      attribute? :gender, Types::String.optional
    end

    # noinspection RubyMismatchedArgumentType
    class StashPerformerFragmentData < Base
      attribute :performer, StashPerformerData
    end

    class StashUrlsData < Base
      attribute :url, Types::String
      attribute :type, Types::String
    end

    class StashImagesData < Base
      attribute :url, Types::String
    end

    class StashStudioData < Base
      attribute :name, Types::String
    end

    class StashAppSceneInput < Base
      attribute :id, Types::String
      attribute :title, Types::String
    end

    # Match this to schema provided in
    # https://github.com/stashapp/stash/blob/develop/graphql/stash-box/query.graphql#L94-L120
    class StashAppSceneFragment < Base
      # id: assigned by stash
      attribute :title, Types::String
      attribute? :code, Types::String # Map this to scene ID created by site
      attribute? :details, Types::String # Scene description
      attribute? :director, Types::String
      # duration: not supported
      attribute? :date, Types::String
      attribute? :urls, Types::Array.of(StashUrlsData).default([].freeze)
      attribute? :images, Types::Array.of(StashImagesData).default([].freeze)
      # noinspection RubyMismatchedArgumentType
      attribute :studio, StashStudioData
      attribute :performers, Types::Array.of(StashPerformerFragmentData).default([].freeze)
      # fingerprints: not supported

      # @param [XxxRename::Data::SceneData] scene_data
      # @return [StashAppSceneFragment]
      # noinspection RubyMismatchedReturnType
      def self.create_from_scene_data(scene_data) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        hash = {}
        hash[:title] = scene_data.title
        hash[:code] = scene_data.id if scene_data.id
        hash[:details] = scene_data.description if scene_data.description
        hash[:director] = scene_data.director if scene_data.director
        hash[:date] = scene_data.date_released.iso8601(3) if scene_data.date_released
        hash[:urls] = [{ url: scene_data.scene_link }] if scene_data.scene_link
        hash[:images] = [{ url: scene_data.scene_cover }] if scene_data.scene_cover
        hash[:studio] = { name: scene_data.collection } if scene_data.collection.presence
        performers = if scene_data.female_actors.empty?
                       scene_data.actors.map { |actor| { performer: { name: actor } } }
                     else
                       scene_data.female_actors.map { |actor| { performer: { name: actor, gender: "FEMALE" } } } +
                         scene_data.male_actors.map { |actor| { performer: { name: actor, gender: "MALE" } } }
                     end
        hash[:performers] = performers

        StashAppSceneFragment.new(hash)
      end

      def to_json(*_args)
        JSON.dump(to_hash)
      end
    end
  end
end
