# frozen_string_literal: true

require "nokogiri"

require "xxx_rename/site_clients/query_generator/goodporn"

module XxxRename
  module SiteClients
    class Goodporn < Base
      include HTTParty

      base_uri "https://goodporn.to"
      site_client_name :goodporn

      # rubocop:disable Style/RegexpLiteral
      HEADLINE_REGEX = /
      (?<collection>[^-]*)                          # Collection
      \s-\s                                         # Separator
      (?<scene_title>.*)                            # Scene Title
      \s-\s                                         # Separator
      (?<date_released>\d\d\/\d\d\/\d\d\d\d)        # Release Date
      /x.freeze
      # rubocop:enable Style/RegexpLiteral

      # rubocop:disable Style/RegexpLiteral
      BRAZZERS_LIVE_HEADLINE_REGEX = /
      -\s                                           # Prefix only for Brazzers Live
      (?<collection>[^-]*)                          # Collection
      :\s?                                          # Scene Separator
      (?<scene_title>[^-]*)                         # Scene Title
      \s-\s                                         # Separator
      (?<date_released>\d\d\/\d\d\/\d\d\d\d)        # Release Date
      /x.freeze
      # rubocop:enable Style/RegexpLiteral

      # @param [String] filename
      # @return [XxxRename::Data::SceneData]
      # rubocop:disable Metrics/CyclomaticComplexity
      def search(filename, **_opts)
        pattern = pattern(filename) || raise(Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, filename))

        doc = Nokogiri::HTML request_search_html(pattern.gsub("-", " "))
        link = search_result_links(doc).select { |url| url.include? pattern }.first
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, filename) if link.nil?

        scene = Nokogiri::HTML request_video_html(link)
        metadata_tags = scene.css("#tab_video_info").css(".info").children.select { |x| x.children.length > 1 }
        actors_hash = actors_hash(actors(metadata_tags))
        match = headline(scene).match(HEADLINE_REGEX) || headline(scene).match(BRAZZERS_LIVE_HEADLINE_REGEX)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, filename) if match.nil? || actors_hash.nil?

        Data::SceneData.new(
          {
            collection: match[:collection],
            collection_tag: "GP",
            title: match[:scene_title],
            id: nil,
            date_released: Time.strptime(match[:date_released], "%m/%d/%Y")
          }.merge(actors_hash)
        )
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      private

      # @param [Hash] actors_hash
      # @return [Array]
      def female_actors(actors_hash)
        actors_hash[:female_actors].nil? ? [] : actors_hash[:female_actors]
      end

      # @param [Hash] actors_hash
      # @return [Array]
      def male_actors(actors_hash)
        actors_hash[:male_actors].nil? ? [] : actors_hash[:male_actors]
      end

      # @param [String] filename
      # @return [nil, String]
      def pattern(filename)
        SiteClients::QueryGenerator::Goodporn.generate(filename, source_format)
      end

      def headline(doc)
        doc.css(".headline").css("h1").text.strip
      end

      def search_result_links(doc)
        search_results = doc.css("#list_videos_videos_list_search_result_items").children
        search_results = search_results.select { |x| x.children.length == 3 }
        search_results.map { |child| child.children[1]["href"] }
      end

      def actors(doc)
        actors = doc.select { |x| x.text.include? "Models" }.first&.children&.css("a")&.map { |x| x.text.strip }
        XxxRename.logger.debug "Unable to fetch actor data".colorize(:red) if actors.nil?
        actors
      end

      def request_search_html(query)
        self.class.get("/search/#{CGI.escape(query)}").body
      end

      def request_video_html(link)
        HTTParty.get(link).body
      end
    end
  end
end
