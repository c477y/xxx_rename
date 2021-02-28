# frozen_string_literal: true

module XxxRename
  class NetworkHelper
    class << self
      def refresh_token_mg(site_url)
        print "Refreshing Instance Token...\n".colorize(:blue)
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
      end

      def fetch_scene_details(results)
        resp = {}
        return resp if results.empty?

        results.each do |scene|
          normalized_title = XxxRename::Utils.normalize(title(scene))

          resp[normalized_title] = {}
          resp[normalized_title][:female_actors] = female_actors(scene)
          resp[normalized_title][:male_actors] = male_actors(scene)
          resp[normalized_title][:collection] = collection(scene)
          resp[normalized_title][:title] = title(scene)
          resp[normalized_title][:date_released] = date_released(scene)
        end

        resp
      end

      private

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
        return nil if collections.empty?

        collections.first["name"]
      end

      def title(scene)
        scene["title"]
      end

      def date_released(scene)
        Time.parse(scene["dateReleased"])
      end
    end
  end
end
