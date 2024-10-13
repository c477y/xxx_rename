# frozen_string_literal: true

module XxxRename
  module SiteClients
    class XEmpire < AlgoliaV2
      SCENES_INDEX_NAME = "all_scenes"
      MOVIES_INDEX_NAME = "all_movies"
      ACTORS_INDEX_NAME = "all_actors"

      CDN_BASE_URL = "https://transform.gammacdn.com"

      site_client_name :x_empire

      def initialize
        @site_url = "https://www.hardx.com"
        super
      end

      # @param [String] _filename
      # @param [Data::ParsedSceneData] parsed_scene_data
      # @param [Boolean] unprocessed
      def search(_filename, parsed_scene_data:, unprocessed:)
        if unprocessed
          parsed_scene_data = Data::ParsedSceneData.new(
            actors: parsed_scene_data.actors,
            title: parsed_scene_data.title.titleize_custom,
            index: parsed_scene_data.index
          )
        end

        if unprocessed
          unprocessed_scene_details(parsed_scene_data)
        else
          processed_scene_details(parsed_scene_data)
        end
      end

      private

      def processed_scene_details(match)
        resp = fetch_scenes_from_api(match.title)

        find_matched_scene!(resp, match)
      end

      def unprocessed_scene_details(match)
        combined = [
          fetch_scenes_from_api(match.title),
          fetch_scenes_from_api("#{match.title} Scene #{match.index}")
        ].reduce([], :concat)

        find_matched_scene!(combined, match)
      end
    end
  end
end
