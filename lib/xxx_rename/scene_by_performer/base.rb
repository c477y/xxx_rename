# frozen_string_literal: true

module XxxRename
  module SceneByPerformer
    class Base
      include HTTParty

      base_uri "https://site-api.project1service.com"

      ACTORS_ENDPOINT = "/v1/actors"
      SEARCH_ENDPOINT = "/v2/releases"

      def initialize(site_url)
        @instance_token = XxxRename::NetworkHelper.refresh_token_mg(site_url)
      end

      def find_all_scenes_by_actor(actor_name)
        actor_details = search_actor(actor_name)

        unless actor_valid? actor_name, actor_details[:actor_name]
          print "Actor Name Mismatch. Searched for #{actor_name.to_s.colorize(:magenta)}." \
          " Found #{actor_details[:actor_name].to_s.colorize(:magenta)}\n"
          return {}
        end

        opts = opt_search_actor_scenes(actor_details[:actor_id])
        response = self.class.get(SEARCH_ENDPOINT, opts)

        raise SearchError, actor_details, opts, response.code, response.body unless response.code == 200

        parsed_response = JSON.parse(response.body)

        total_scenes = parsed_response["meta"]["total"]
        if total_scenes > 100
          print "Total number of scenes for actor name #{actor_name} is #{total_scenes}." \
          " Pagination is not implemented. This might cause a few scenes to not match.".colorize(:red)
        end

        XxxRename::NetworkHelper.fetch_scene_details(parsed_response["result"])
      end

      private

      def opt_search_actor(actor_name)
        {
          query: {
            search: actor_name,
            limit: 1
          },
          headers: {
            "Instance" => @instance_token,
            "User-Agent" => "Mozilla/5.0 (platform; rv:geckoversion) Gecko/geckotrail Firefox/firefoxversion"
          },
          timeout: 5
        }
      end

      def opt_search_actor_scenes(actor_id, limit: 100, offset: 0)
        {
          query: {
            type: "scene",
            limit: limit,
            offset: offset,
            actorId: actor_id
          },
          headers: {
            "Instance" => @instance_token,
            "User-Agent" => "Mozilla/5.0 (platform; rv:geckoversion) Gecko/geckotrail Firefox/firefoxversion"
          },
          timeout: 5
        }
      end

      def search_actor(actor_name)
        opts = opt_search_actor(actor_name)
        response = self.class.get(ACTORS_ENDPOINT, opts)
        parsed_response = JSON.parse(response.body)

        if parsed_response["result"].empty? || response.code != 200
          raise SearchError, actor_name, opts, response.code, response.body
        end

        {
          actor_name: parsed_response["result"].first["name"],
          actor_id: parsed_response["result"].first["id"]
        }
      end

      def actor_valid?(search_actor, response_actor)
        XxxRename::Utils.normalize(search_actor) == XxxRename::Utils.normalize(response_actor)
      end
    end
  end
end
