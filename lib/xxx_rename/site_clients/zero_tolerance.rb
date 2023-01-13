# frozen_string_literal: true

require "xxx_rename/site_clients/algolia_v2"
require "xxx_rename/site_clients/query_generator/base"

module XxxRename
  module SiteClients
    class ZeroTolerance < AlgoliaV2
      SCENES_INDEX_NAME = "all_scenes"
      MOVIES_INDEX_NAME = "all_movies"

      site_client_name :zero_tolerance

      CDN_BASE_URL = "https://transform.gammacdn.com"

      def initialize(config)
        @site_url = "https://www.zerotolerancefilms.com"
        super(config)
      end

      def search(filename)
        match = SiteClients::QueryGenerator::Base.generic_generate(filename, source_format)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, filename) unless match&.title&.presence

        search_results = search_scene_using_title(match.title)
        find_matched_scene!(search_results, match)
      end

      private

      def search_scene_using_title(title)
        with_retry { scenes_index.search(title, default_query)&.[](:hits) }
      end
    end
  end
end
