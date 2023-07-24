# frozen_string_literal: true

require "xxx_rename/site_clients/query_generator/vixen"

module XxxRename
  module SiteClients
    class VixenMedia < Base
      include HTTParty
      include Utils

      headers "content-type" => "application/json"

      GRAPHQL_ENDPOINT = "/graphql"

      def search(filename)
        match = SiteClients::QueryGenerator::Vixen.generate(filename, source_format)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, filename) if match.nil?

        if match.id && match.collection
          get_video_by_id(match.id, match.collection)
        elsif match.title && match.actors
          get_video_by_metadata(match.title, match.actors)
        else
          raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, filename)
        end
      end

      private

      def get_video_by_id(video_id, site)
        api_resp = self.class.post(GRAPHQL_ENDPOINT, body: body(video_id, site))
        resp = handle_response! { api_resp }

        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, "#{site}-#{video_id}") if resp.dig("data", "findOneVideo").nil?

        Data::SceneData.new(
          {
            collection: site,
            collection_tag: site_config.collection_tag,
            title: resp.dig("data", "findOneVideo", "title"),
            id: resp.dig("data", "findOneVideo", "videoId").to_s,
            date_released: Time.parse(resp.dig("data", "findOneVideo", "releaseDate"))
          }.merge(actors_hash(resp.dig("data", "findOneVideo", "modelsSlugged").map { |m| m["name"] }))
        )
      end

      def get_video_by_metadata(title, actors)
        req_body = search_results_body("#{title} #{actors.join(", ")}")
        api_resp = handle_response! { self.class.post(GRAPHQL_ENDPOINT, body: req_body) }

        search_results = api_resp.dig("data", "searchVideos", "edges")
        search_results.map do |search_result_node|
          search_result = search_result_node["node"]
          next if search_result.nil? || !scene_match?(search_result, title, actors)

          return Data::SceneData.new(
            {
              collection: site,
              collection_tag: site_config.collection_tag,
              title: search_result["title"],
              id: search_result["videoId"].to_s,
              date_released: Time.parse(search_result["releaseDate"])
            }.merge(actors_hash(search_result["modelsSlugged"].map { |m| m["name"] }))
          )
        end

        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, "#{title}-#{actors.join(",")}") if search_results.blank?
      end

      def scene_match?(search_result, title, actors)
        actors_n = actors.map(&:normalize).to_set
        res_actors_n = search_result["modelsSlugged"].map { |x| x["name"].normalize }.to_set
        match?(search_result["title"], title) && actors_n.subset?(res_actors_n)
      end

      # Generate the POST body
      #
      # @return [JSON]
      def body(video_id, site)
        {
          "operationName": "getVideo",
          "variables": {
            "videoId": video_id,
            "site": site
          },
          "query": <<~GRAPHQL
            query getVideo($videoId: ID, $site: Site) {
              findOneVideo(input: { videoId: $videoId, site: $site }) {
                id: uuid
                videoId
                title
                releaseDate
                modelsSlugged: models {
                  name
                }
              }
            }
          GRAPHQL
        }.to_json
      end

      def search_results_body(query)
        {
          "operationName": "getSearchResults",
          "variables": {
            "query": query,
            "site": site,
            "first": 5
          },
          "query": <<~GRAPHQL
            query getSearchResults($query: String!, $site: Site!, $first: Int) {
              searchVideos(input: { query: $query, site: $site, first: $first }) {
                edges {
                  node {
                    videoId
                    title
                    releaseDate
                    modelsSlugged: models {
                      name
                    }
                  }
                }
              }
            }
          GRAPHQL
        }.to_json
      end

      def site
        self.class.site_client_name.to_s.upcase.gsub("_", "")
      end
    end
  end
end
