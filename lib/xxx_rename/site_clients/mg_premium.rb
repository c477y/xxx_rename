# frozen_string_literal: true

require "xxx_rename/site_clients/query_generator/mg_premium"

module XxxRename
  module SiteClients
    class MGPremium < Base
      include HTTParty
      include Utils

      base_uri "https://site-api.project1service.com"

      SEARCH_ENDPOINT = "/v2/releases"
      ACTOR_ENDPOINT = "/v1/actors"

      # @param [XxxRename::Data::Config] config
      # @param [String] site_url
      def initialize(config, site_url:)
        @site_url = site_url
        super(config)
      end

      # @param [String] filename
      # @return [Hash{Symbol->Array | String | Time}, nil] A Hash containing details extracted from the file.
      # @param [Hash] opts
      # @option opts [Boolean] recursive If needed to search for a file recursively
      def search(filename, **opts)
        str = search_scene_title(filename)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, filename) if str.nil?

        @normalized_scene_name = str.normalize

        scene_resp = api_search(str)
        return scene_resp[@normalized_scene_name] unless scene_resp[@normalized_scene_name].nil?

        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, str) unless opts[:recursive]

        scene_resp = recursive_search(str)
        scene_resp || raise(Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, str))
      end

      def actor_details(actor)
        opts = opt_search_actor(actor)
        response = self.class.get(ACTOR_ENDPOINT, opts)
        return unless response.code == 200

        response["result"]&.select { |x| match? actor, x["name"] }&.first&.slice("name", "gender")
      end

      private

      # @param [String] search_string Search parameter
      # @return [Hash{Symbol->Array | String | Time}, nil]
      def recursive_search(search_string)
        while search_string.length >= 3
          search_string = reduce_search_string(search_string)
          XxxRename.logger.debug "Trying with #{search_string.to_s.colorize(:blue)}"
          scene = api_search(search_string)
          return scene[@normalized_scene_name] unless scene[@normalized_scene_name].nil?
        end
      end

      def api_search(search_string)
        opts = opt_search_scene(search_string)
        response = self.class.get(SEARCH_ENDPOINT, opts)

        case response.code
        when 200
          parsed_response = JSON.parse(response.body)
          fetch_scene_details(parsed_response["result"])
        when 404
          parsed_response = JSON.parse(response.body)
          if parsed_response.is_a?(Array) && banned_search?(parsed_response.first["errors"])
            reduced_search_string = reduce_search_string(search_string)
            XxxRename.logger.debug "Got banned search error with search string" \
                  "#{search_string.to_s.colorize(:red)}. Trying with" \
                  "#{reduced_search_string.to_s.colorize(:red)}\n"
            api_search(reduced_search_string)
          else
            obj = {
              request_options: opts,
              response_code: response.code,
              response_body: response.body
            }
            raise Errors::SearchError.new(search_string, obj)
          end
        else
          handle_response! { response }
        end
      end

      # @param [String] search_string
      # @return [String]
      def reduce_search_string(search_string)
        # Remove last 5 characters
        search_string.chop.chop.chop.chop.chop
      end

      def banned_search?(errors)
        errors.each do |err|
          return true if err["code"] == 1750
        end
        false
      end

      def opt_search_actor(actor)
        {
          query: {
            limit: 10,
            search: actor
          },
          headers: {
            "Instance" => instance_token,
            "User-Agent" => "Mozilla/5.0 (platform; rv:geckoversion) Gecko/geckotrail Firefox/firefoxversion"
          },
          timeout: 5
        }
      end

      def opt_search_scene(scene_name)
        {
          query: {
            type: "scene",
            limit: 10,
            search: scene_name
          },
          headers: {
            "Instance" => instance_token,
            "User-Agent" => "Mozilla/5.0 (platform; rv:geckoversion) Gecko/geckotrail Firefox/firefoxversion"
          },
          timeout: 5
        }
      end

      def instance_token(refresh = false)
        @instance_token = refresh_token_mg(@site_url) if @instance_token.nil?
        @instance_token = refresh_token_mg(@site_url) if refresh

        @instance_token
      end

      def refresh_token_mg(site_url)
        XxxRename.logger.debug "Refreshing Instance Token...".colorize(:blue)
        response = HTTParty.get(site_url)
        case response.code
        when 429
          raise "Failed to refresh instance token. Too many requests made..."
        when 200
          cookie_header = response.headers["set-cookie"].to_s
          instance_token_param = cookie_header.split(";").first
          instance_token_param.sub("instance_token=", "")
        else
          raise "Error in refreshing instance token: #{response.code}"
        end
      rescue OpenSSL::SSL::SSLError
        raise "Unable to open connection to #{site_url}. Check your internet connection and try again."
      end

      def fetch_scene_details(results)
        resp = {}
        return resp if results.empty?

        results.each do |scene|
          normalized_title = title(scene).normalize

          hash = {}.tap do |h|
            h[:collection] = collection(scene)
            h[:collection_tag] = site_config.collection_tag
            h[:title] = title(scene)
            h[:id] = scene_id(scene)
            h[:date_released] = date_released(scene)
            h[:movie] = movie_hash(scene) unless movie_hash(scene).nil?
            h[:female_actors] = female_actors(scene)
            h[:male_actors] = male_actors(scene)
            h[:actors] = female_actors(scene) + male_actors(scene)
            h[:description] = description(scene)
            h[:scene_link] = scene_link(scene)
          end
          resp[normalized_title] = Data::SceneData.new(hash)
        end

        resp
      end

      def movie_hash(scene)
        return nil if scene["parent"].nil?

        parent = scene["parent"]
        type = parent["type"] == "serie" ? "series" : parent["type"]
        {
          name: parent["title"],
          date: Time.parse(parent["dateReleased"]),
          url: URI.join(@site_url, "/#{type}/", "#{parent["id"]}/", parent["title"].downcase.gsub(" ", "-")).to_s,
          front_image: extract_image_url(parent),
          studio: parent.dig("brandMeta", "displayName"),
          synopsis: parent["description"]
        }
      end

      def extract_image_url(hash)
        cover_hash = hash.dig("images", "cover", "0") || hash.dig("images", "poster", "0")
        return if cover_hash.nil?

        res = %w[xx xl lg md sm].find { |x| cover_hash.key?(x) }
        cover_hash.dig(res, "url") || cover_hash.dig(res, "urls", "default")
      end

      def female_actors(scene)
        scene["actors"]
          .select { |actor| actor["gender"] == "female" }
          .map { |actor| actor["name"] }
          .sort
      end

      def male_actors(scene)
        scene["actors"]
          .select { |actor| actor["gender"] == "male" }
          .map { |actor| actor["name"] }
          .sort
      end

      def collection(scene)
        collections = scene["collections"]
        return "" if collections.empty?

        collections.first["name"]
      end

      def title(scene)
        scene["title"]
      end

      def scene_id(scene)
        scene["id"]
      end

      def date_released(scene)
        Time.parse(scene["dateReleased"])
      end

      def description(scene)
        scene["description"]
      end

      def scene_link(scene)
        "#{@site_url}/video/#{scene_id(scene)}/#{scene_slug(scene)}"
      end

      def scene_slug(scene)
        scene["title"].downcase.gsub(" ", "-").gsub(/\W/, "").to_s
      end

      def search_scene_title(filename)
        # TODO: Allow client to use section of parameters rather than just the scene title
        resp = SiteClients::QueryGenerator::MgPremium.generate(filename, source_format)

        resp&.title&.downcase
      end
    end
  end
end
