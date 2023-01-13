# frozen_string_literal: true

require "xxx_rename/site_clients/algolia_v2"
require "xxx_rename/site_clients/query_generator/base"

module XxxRename
  module SiteClients
    class AdultTime < AlgoliaV2
      SCENES_INDEX_NAME = "all_scenes"
      MOVIES_INDEX_NAME = "all_movies"
      ACTORS_INDEX_NAME = "all_actors"

      CDN_BASE_URL = "https://transform.gammacdn.com"

      site_client_name :adult_time

      def initialize(config)
        @site_url = "https://www.milkingtable.com"
        super(config)
      end

      def search(filename)
        match = SiteClients::QueryGenerator::Base.generic_generate(filename, source_format)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, filename) if match.nil? || match.title.blank?

        resp = fetch_scenes_from_api(match.title)
        find_matched_scene!(resp, match)
      end
    end
  end
end
