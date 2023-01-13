# frozen_string_literal: true

require "xxx_rename/site_clients/algolia_v2"
require "xxx_rename/site_clients/query_generator/base"

module XxxRename
  module SiteClients
    class Wicked < AlgoliaV2
      SCENES_INDEX_NAME = "all_scenes"
      MOVIES_INDEX_NAME = "all_movies"
      ACTORS_INDEX_NAME = "all_actors"

      CDN_BASE_URL = "https://transform.gammacdn.com"

      site_client_name :wicked

      def initialize(config)
        @site_url = "https://www.wicked.com"
        super(config)
      end

      def search(filename)
        match = QueryGenerator::Base.generic_generate(filename, source_format)
        title = match&.title.presence || filename.split("_").first&.titleize_custom

        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, filename) unless title.presence

        resp = fetch_scenes_from_api(title)
        find_matched_scene!(resp, title)
      end

      def actor_details(actor)
        response = fetch_actor_from_api(actor)
        response&.select { |x| match? actor, x[:name] }
          &.first
          &.slice(:name, :gender)
          &.transform_keys(&:to_s) # Backwards compatibility. Keys should be strings.
      end

      private

      def find_matched_scene!(search_results, title)
        scenes = search_results.reject { |x| x[:release_date].nil? }
                               .select { |x| match?(x[:title], title) }

        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, title) if scenes.length != 1

        make_scene_data(scenes.first)
      end
    end
  end
end
