# frozen_string_literal: true

require "xxx_rename/site_clients/algolia_v2"
require "xxx_rename/site_clients/query_generator/evil_angel"

module XxxRename
  module SiteClients
    class XEmpire < AlgoliaV2
      SCENES_INDEX_NAME = "all_scenes"
      MOVIES_INDEX_NAME = "all_movies"
      ACTORS_INDEX_NAME = "all_actors"

      CDN_BASE_URL = "https://transform.gammacdn.com"

      site_client_name :x_empire

      def initialize(config)
        @site_url = "https://www.hardx.com"
        super(config)
      end

      def search(filename)
        match = SiteClients::QueryGenerator::EvilAngel.generate(filename, source_format)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, filename) if match.nil?

        if match.processed
          processed_scene_details(match)
        else
          unprocessed_scene_details(match)
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
