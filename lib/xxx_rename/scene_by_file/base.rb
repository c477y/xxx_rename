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

      def search(file, limit)
        scene_title_arr = XxxRename::Utils.scene_name(file).split("-")
        search_string = XxxRename::Utils.adjust_apostrophe(scene_title_arr)

        opts = opt_search_scene(search_string, limit)
        response = self.class.get(SEARCH_ENDPOINT, opts)

        case response.code
        when 429
          raise TooManyRequestsError, SEARCH_ENDPOINT
        when 200
          parsed_response = JSON.parse(response.body)
          XxxRename::NetworkHelper.fetch_scene_details(parsed_response["result"])
        else
          obj = {
            request_options: opts,
            response_code: response.code,
            response_body: response.body
          }
          raise SearchError.new(file, obj)
        end
      end

      private

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
