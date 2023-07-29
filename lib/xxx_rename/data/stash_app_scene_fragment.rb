# frozen_string_literal: true

module XxxRename
  module Data
    class StashPerformerData < Base
      attribute :name, Types::String
      attribute? :gender, Types::String.optional
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
      attribute? :url, Types::String
      attribute? :image, Types::String
      # noinspection RubyMismatchedArgumentType
      attribute :studio, StashStudioData
      attribute :performers, Types::Array.of(StashPerformerData).default([].freeze)
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
        hash[:url] = scene_data.scene_link if scene_data.scene_link
        hash[:image] = scene_data.scene_cover if scene_data.scene_cover
        hash[:studio] = { name: scene_data.collection } if scene_data.collection.presence
        performers = if scene_data.female_actors.empty?
                       scene_data.actors.map { |actor| { name: actor } }
                     else
                       scene_data.female_actors.map { |actor| { name: actor, gender: "FEMALE" } } +
                         scene_data.male_actors.map { |actor| { name: actor, gender: "MALE" } }
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
