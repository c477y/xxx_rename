# frozen_string_literal: true

module XxxRename
  module SceneByFile
    class Base
      include HTTParty

      base_uri "https://site-api.project1service.com"

      SEARCH_ENDPOINT = "/v2/releases"

      def initialize(site_url)
        @site_url = site_url
        @instance_token = XxxRename::NetworkHelper.refresh_token_mg(site_url)
      end

      def search(search_string, limit)
        opts = opt_search_scene(search_string, limit)
        response = self.class.get(SEARCH_ENDPOINT, opts)

        case response.code
        when 429
          raise TooManyRequestsError, SEARCH_ENDPOINT
        when 200
          parsed_response = JSON.parse(response.body)
          XxxRename::NetworkHelper.fetch_scene_details(parsed_response["result"])
        when 404
          parsed_response = JSON.parse(response.body)
          if parsed_response.is_a?(Array) && banned_search?(parsed_response.first["errors"])
            reduced_search_string = reduce_search_string(search_string)
            print "Got banned search error with search string \
#{search_string.to_s.colorize(:red)}. Trying with \
#{reduced_search_string.to_s.colorize(:red)}\n"
            search(reduced_search_string, 25)
          else
            obj = {
              request_options: opts,
              response_code: response.code,
              response_body: response.body
            }
            raise SearchError.new(search_string, obj)
          end
        else
          # binding.pry
          obj = {
            request_options: opts,
            response_code: response.code,
            response_body: response.body
          }
          raise SearchError.new(search_string, obj)
        end
      end

      private

      # Removes last alphabet from the search string
      def reduce_search_string(search_string)
        search_string.chop
      end

      def banned_search?(errors)
        errors.each do |err|
          return true if err["code"] == 1750
        end
        false
      end

      def opt_search_scene(scene_name, limit)
        {
          query: {
            type: "scene",
            limit: limit,
            search: scene_name
          },
          headers: {
            "Instance" => @instance_token,
            "User-Agent" => "Mozilla/5.0 (platform; rv:geckoversion) Gecko/geckotrail Firefox/firefoxversion"
          },
          timeout: 5
        }
      end
    end
  end
end
