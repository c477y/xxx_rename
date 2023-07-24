# frozen_string_literal: true

require "xxx_rename/site_clients/query_generator/stash_db"

module XxxRename
  module SiteClients
    class StashDb < Base
      include HTTParty
      include Utils

      base_uri "https://stashdb.org"
      headers "Content-Type" => "application/json"

      site_client_name :stash

      LOGIN_ENDPOINT = "/login"
      GRAPHQL_ENDPOINT = "/graphql"

      attr_reader :username, :password

      def initialize(config)
        @cookie_set = false
        @api_key_set = false
        super(config)
      end

      # @param [String] filename
      # @return [XxxRename::Data::SceneData, nil]
      # noinspection RubyMismatchedReturnType
      def search(filename)
        setup_credentials! if login_required?

        match = search_query(filename)
        scene_id = find_matching_scene_id!(match)
        scene_details(scene_id)
      end

      def setup_credentials!
        if username_password_provided?
          login_using_credentials(site_config.username, site_config.password)
        elsif api_key_provided?
          register_api_key(site_config.api_token)
          validate_credentials!
        else
          raise Errors::InvalidCredentialsError, self.class.name
        end
      end

      def actor_details(actor)
        return unless credentials_provided?

        setup_credentials! if login_required?
        response = handle_response! { self.class.post(GRAPHQL_ENDPOINT, body: actor_search_query(actor)) }
        response.dig("data", "searchPerformer")&.select { |x| match?(x["name"], actor) }&.first
      end

      private

      def login_using_credentials(username, password)
        body = { username: username, password: password }
        resp = handle_response!(return_raw: true) { self.class.post(LOGIN_ENDPOINT, body: body, multipart: true) }
        cookie_hash = HTTParty::CookieHash.new
        resp.get_fields("Set-Cookie").each { |c| cookie_hash.add_cookies(c) }
        @cookie_set = true
        cookie_s = cookie_hash.to_cookie_string
        self.class.headers "cookie" => cookie_s
        cookie_s
      end

      def login_required?
        true unless @cookie_set || @api_key_set
      end

      def register_api_key(api_key)
        @api_key_set = true
        self.class.headers "ApiKey" => api_key
      end

      def credentials_provided?
        username_password_provided? || api_key_provided?
      end

      def username_password_provided?
        [site_config.username, site_config.password].map(&:to_s).map(&:presence).all?(String)
      end

      def api_key_provided?
        site_config.api_token.to_s.presence.is_a?(String)
      end

      def validate_credentials!
        body = {
          operationName: "Version",
          query: <<~GRAPHQL
            query Version {
              version {
                version
              }
            }
          GRAPHQL
        }.to_json
        resp = handle_response! { self.class.post(GRAPHQL_ENDPOINT, body: body) }
        resp.dig("data", "version", "version")
      end

      def scene_details(scene_id)
        graphql_fetch_scene_details(scene_id)
      end

      def find_matching_scene_id!(scene_data)
        if scene_data.actors.present?
          resp = search_with_title_and_actors(scene_data, 10)
          return resp["id"] if resp.present?
        end

        resp = search_with_title(scene_data, 10)
        return resp["id"] if resp.present?

        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, scene_data.title)
      end

      def search_with_title(scene_data, limit)
        term = scene_data.title
        search_results = graphql_search(term, limit)
        search_results.select do |x|
          match?(x["title"], scene_data.title) || match?(x.dig("studio", "name"), scene_data.title)
        end.first
      end

      def search_with_title_and_actors(scene_data, limit)
        actors = (scene_data.female_actors + scene_data.actors).compact.uniq!
        term = "#{actors.join(", ")} #{scene_data.title}"
        search_results = graphql_search(term, limit)
        search_results.select do |x|
          cond1 = match?(x["title"], scene_data.title) || match?(x.dig("studio", "name"), scene_data.title)
          cond2 = actors_included?(x, actors)
          cond1 && cond2
        end.first
      end

      # @param [String] filename
      # @return [XxxRename::SiteClients::QueryGenerator::Base::SearchParameters]
      # @raise XxxRename::Errors::NoMatchError
      def search_query(filename)
        resp = SiteClients::QueryGenerator::StashDb.generate(filename, source_format)

        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, filename) if resp.nil?

        resp
      end

      # @param [String] term
      # @param [Integer] limit
      # @return [Array[Hash]]
      # @raise XxxRename::SearchError
      def graphql_search(term, limit)
        resp = self.class.post(GRAPHQL_ENDPOINT, body: grapql_body(term, limit))
        if resp.code != 200
          opts = { request_options: nil, response_code: resp.code, response_body: resp.body }
          raise Errors::SearchError.new(term, opts)
        end

        resp.parsed_response.dig("data", "searchScene") || []
      end

      def graphql_fetch_scene_details(scene_id)
        resp = handle_response! { self.class.post(GRAPHQL_ENDPOINT, body: graphql_fetch_scene_details_body(scene_id)) }
        scene = resp["data"]["findScene"]
        hash = {}
        hash[:female_actors] = female_actors(scene)
        hash[:male_actors] = male_actors(scene)
        hash[:actors] = female_actors(scene) + male_actors(scene)
        hash[:collection] = scene.dig("studio", "name")
        hash[:collection_tag] = site_config.collection_tag
        hash[:title] = scene["title"]
        hash[:id] = scene["id"]
        hash[:date_released] = Time.strptime(scene["release_date"], "%Y-%m-%d")
        hash[:director] = scene["director"] if scene["director"]
        hash[:description] = scene["details"] if scene["details"]
        hash[:scene_link] = scene_link(scene) if scene_link(scene)
        hash[:scene_cover] = scene_cover(scene) if scene_cover(scene)
        Data::SceneData.new(hash)
      end

      # @param [Hash] scene
      # @return [Array[String]]
      def female_actors(scene)
        actors(scene)
          .select { |x| x["gender"] == "FEMALE" }
          .map {  |x| x["name"] }
      end

      # @param [Hash] scene
      # @return [Array[String]]
      def male_actors(scene)
        actors(scene)
          .select { |x| x["gender"] == "MALE" }
          .map {  |x| x["name"] }
      end

      def scene_link(scene)
        scene["urls"].find { |x| x.dig("site", "name") == "Studio" }&.[]("url")
      end

      def scene_cover(scene)
        scene["images"].first&.[]("url")
      end

      # Return an Array of Array[Actor]. The first element of the array main actor name and the others are aliases
      # @param [Hash] scene
      # @return [Array[Array[String]]]
      def actors_arr(scene, gender)
        actors(scene)
          .select { |x| x["gender"] == gender }
          .map {  |x| [x["name"]] + x["aliases"] }
      end

      def female_actors_arr(scene)
        actors_arr(scene, "FEMALE")
      end

      def male_actors_arr(scene)
        actors_arr(scene, "MALE")
      end

      # Return an Array of Array[Actor]. The first element of the array main actor name and the others are aliases
      # @param [Hash] scene
      # @return [Array[Array[String]]]
      def male_actors_hash(scene)
        actors(scene)
          .select { |x| x["gender"] == "FEMALE" }
          .map {  |x| [x["name"]] + x["aliases"] }
      end

      # @param [Hash] scene
      # @return [Hash]
      def actors(scene)
        scene["performers"]
          .map { |x| x["performer"] }
          .map { |x| x.slice("name", "gender", "aliases") }
      end

      # @param [Hash] scene
      # @param [Array[String]] female_actors
      def actors_included?(scene, actors)
        female_actors_search = female_actors_arr(scene).flatten.map(&:normalize).to_set
        male_actors_search = male_actors_arr(scene).flatten.map(&:normalize).to_set
        rej = actors.reject do |actor|
          female_actors_search.member?(actor.normalize) || male_actors_search.member?(actor.normalize)
        end
        rej.empty?
      end

      # @return [Hash{Symbol->Unknown}]
      # @param [String] term
      # @param [Integer] limit
      def grapql_body(term, limit)
        {
          operationName: "SearchAll",
          variables:
            { limit: limit,
              term: term },
          query: <<~GRAPHQL
            query SearchAll($term: String!, $limit: Int = 5) {
              searchScene(term: $term, limit: $limit) {
                id
                date
                title
                studio {
                  name
                }
                performers {
                  as
                  performer {
                    id
                    name
                    gender
                    aliases
                  }
                }
              }
            }
          GRAPHQL
        }.to_json
      end

      def graphql_fetch_scene_details_body(scene_id)
        {
          operationName: "Scene",
          variables: { id: scene_id },
          query: <<~GRAPHQL
            query Scene($id: ID!) {
              findScene(id: $id) {
                id
                release_date
                title
                details
                director
                urls {
                  url
                  site {
                    id
                    name
                    icon
                  }
                }
                images {
                  id
                  url
                  width
                  height
                }
                studio {
                  id
                  name
                  parent {
                    id
                    name
                  }
                }
                performers {
                  as
                  performer {
                    id
                    name
                    disambiguation
                    deleted
                    gender
                    aliases
                  }
                }
                tags {
                  id
                  name
                  description
                  aliases
                }
              }
            }
          GRAPHQL
        }.to_json
      end

      def actor_search_query(actor)
        {
          operationName: "SearchPerformers",
          variables: { term: actor },
          query: <<~GRAPHQL
            query SearchPerformers($term: String!, $limit: Int = 5) {
              searchPerformer(term: $term, limit: $limit) {
              name
              gender
              }
            }
          GRAPHQL
        }.to_json
      end
    end
  end
end
