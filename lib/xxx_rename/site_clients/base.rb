# frozen_string_literal: true

require "httparty"
require "xxx_rename/site_clients/configuration"
require "xxx_rename/utils"

module XxxRename
  module SiteClients
    class Base
      include Utils
      include SiteClients::Configuration

      attr_reader :source_format, :config

      # @param [XxxRename::Data::Config] config
      def initialize(config)
        @actors_helper = config.actor_helper
        @config = config
        @source_format = site_config.file_source_format
        return unless self.class.include?(HTTParty)

        self.class.logger(XxxRename.logger, :debug)
        self.class.headers(Constants::DEFAULT_HEADERS)
      end

      def search(_filename, **_opts)
        raise "Not Implemented."
      end

      private

      def match?(str1, str2)
        str1.normalize == str2.normalize
      end

      def contains?(str1, str2)
        str1.normalize.include?(str2.normalize)
      end

      def actors_hash(actors)
        actors.each { |x| @actors_helper.auto_fetch! x }
        female_actors = actors.select { |x| @actors_helper.female? x }
        male_actors = actors.select { |x| @actors_helper.male? x }
        resp = { female_actors: female_actors,
                 male_actors: male_actors,
                 actors: female_actors + male_actors }
        diff = (resp[:female_actors] + resp[:male_actors]) - actors
        raise "Actors #{diff.join(", ")} removed from response even after being processed." if diff.length > 1

        resp
      rescue XxxRename::Errors::UnprocessedEntity => e
        XxxRename.logger.warn "Unable to fetch details of actor #{e.message}"
        {
          female_actors: [],
          male_actors: [],
          actors: actors
        }
      end

      def slug(str)
        str.to_s.downcase.gsub(" ", "-").gsub(/[^\w-]/, "")
      end
    end
  end
end
