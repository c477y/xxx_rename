# frozen_string_literal: true

module XxxRename
  module SiteClients
    class Base
      include HTTParty
      include Utils
      include SiteClients::Configuration

      attr_reader :source_format

      headers "Accept" => "application/json"
      headers "Connection" => "keep-alive"
      headers "Content-Type" => "application/json"
      headers "DNT" => "1"
      headers "User-Agent" => "Mozilla/5.0 (Windows NT x.y; rv:10.0) Gecko/20100101 Firefox/10.0"

      def initialize
        @source_format = site_config.file_source_format
        self.class.logger XxxRename.logger, :trace
      end

      def search(_filename, _parsed_scene_data:, _unprocessed:)
        raise "Not Implemented."
      end

      def actor_helper
        config.actor_helper
      end

      private

      def config
        XxxRename.config
      end

      def match?(str1, str2)
        str1.normalize == str2.normalize
      end

      def contains?(str1, str2)
        str1.normalize.include?(str2.normalize)
      end

      def actors_hash(actors)
        actors.each { |x| actor_helper.auto_fetch! x }
        female_actors = actors.select { |x| actor_helper.female? x }
        male_actors = actors.select { |x| actor_helper.male? x }
        resp = { female_actors: female_actors,
                 male_actors: male_actors,
                 actors: female_actors + male_actors }
        diff = (resp[:female_actors] + resp[:male_actors]) - actors
        raise "Actors #{diff.join(", ")} removed from response even after being processed." if diff.length > 1

        resp
      rescue XxxRename::Errors::UnprocessedEntity => e
        XxxRename.logger.warn "[ACTOR DETAILS FETCH ERROR] #{e.message}"
        {
          female_actors: [],
          male_actors: [],
          actors: actors
        }
      end

      def slug(str)
        str.to_s.downcase.gsub(" ", "-").gsub(/[^\w-]/, "")
      end

      def doc(path)
        path = "/#{path}" unless path.start_with?("/")

        res = handle_response!(return_raw: true) { self.class.get(path) }
        Nokogiri::HTML(res.body)
      end
    end
  end
end
