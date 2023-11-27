# frozen_string_literal: true

module XxxRename
  module SiteClients
    class ZeroTolerance < AlgoliaV2
      SCENES_INDEX_NAME = "all_scenes"
      MOVIES_INDEX_NAME = "all_movies"

      site_client_name :zero_tolerance

      CDN_BASE_URL = "https://transform.gammacdn.com"

      def initialize
        @site_url = "https://www.zerotolerancefilms.com"
        super
      end

      # @param [String] filename
      # @param [Data::ParsedSceneData] parsed_scene_data
      def search(filename, parsed_scene_data:, unprocessed:)
        search_results = search_scene_using_title(parsed_scene_data.title)
        find_matched_scene!(search_results, parsed_scene_data)
      end

      private

      def search_scene_using_title(title)
        with_retry { scenes_index.search(title, default_query)&.[](:hits) }
      end
    end
  end
end
