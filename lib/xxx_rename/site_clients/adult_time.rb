# frozen_string_literal: true

module XxxRename
  module SiteClients
    class AdultTime < AlgoliaV2
      SCENES_INDEX_NAME = "all_scenes"
      MOVIES_INDEX_NAME = "all_movies"
      ACTORS_INDEX_NAME = "all_actors"

      CDN_BASE_URL = "https://transform.gammacdn.com"

      site_client_name :adult_time

      def initialize
        @site_url = "https://www.milkingtable.com"
        super
      end

      # @param [String] filename
      # @param [Data::ParsedSceneData] parsed_scene_data
      # @param [Boolean] unprocessed
      def search(filename, parsed_scene_data:, unprocessed: false)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, filename) if parsed_scene_data.empty?

        resp = fetch_scenes_from_api(parsed_scene_data.title)
        find_matched_scene!(resp, parsed_scene_data)
      end
    end
  end
end
