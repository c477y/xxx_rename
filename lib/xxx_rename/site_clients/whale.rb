# frozen_string_literal: true

require "nokogiri"

require "xxx_rename/site_clients/query_generator/whale"

module XxxRename
  module SiteClients
    class Whale < Base
      include HTTParty

      URL_MAPPER = {
        nannyspy: "https://nannyspy.com",
        spyfam: "https://spyfam.com",
        holed: "https://holed.com",
        lubed: "https://lubed.com",
        myveryfirsttime: "https://myveryfirsttime.com",
        tiny4k: "https://tiny4k.com",
        povd: "https://povd.com",
        fantasyhd: "https://fantasyhd.com",
        castingcouchx: "https://castingcouch-x.com",
        puremature: "https://puremature.com",
        passionhd: "https://passion-hd.com",
        exotic4k: "https://exotic4k.com"
      }.freeze

      COLLECTION_MAPPER = {
        nannyspy: "Nanny Spy",
        spyfam: "Spyfam",
        holed: "Holed",
        lubed: "Lubed",
        myveryfirsttime: "My Very First Time",
        tiny4k: "Tiny4k",
        povd: "PovD",
        fantasyhd: "FantasyHD",
        castingcouchx: "Casting Couch X",
        puremature: "Puremature",
        passionhd: "PassionHD",
        exotic4k: "Exotic 4K"
      }.freeze

      site_client_name :whale_media

      # @param [String] filename
      # @return [Hash, NilClass]
      def search(filename)
        match = SiteClients::QueryGenerator::Whale.generate(filename, source_format)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, filename) if match.nil?

        unless URL_MAPPER.key?(match[:collection])
          raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_CUSTOM,
                                         "Unknown site collection #{match[:collection]}")
        end

        url = make_url(match)
        collection = COLLECTION_MAPPER.fetch(match[:collection], "Whale Media")
        fetch_details_from_html(url, collection)
      end

      private

      # @param [String] url
      # @return [Hash, NilClass]
      def fetch_details_from_html(url, collection)
        XxxRename.logger.debug "Scraping data from #{url.to_s.colorize(:blue)}"
        web_resp = HTTParty.get(url, follow_redirects: false)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, url) unless web_resp.code == 200

        search_string = url.split("/").last
        parse_scene_details(web_resp.body, search_string, collection)
      end

      # @param [Nokogiri::HTML::Document] body
      # @param [String] search_string
      # @param [String] collection
      # @return [Hash, NilClass]
      # noinspection RubyMismatchedReturnType
      def parse_scene_details(body, search_string, collection)
        doc = Nokogiri::HTML(body)
        normalised_title = title(doc)
                           .downcase
                           .gsub("-", "")
                           .gsub(/['"“”‘’„]/, "-")
                           .gsub(/[^\s\w-]/, "")
                           .gsub(/\s{2,}/, " ")
                           .gsub(/\s/, "-")
        Data::SceneData.new(
          female_actors: female_actors(doc),
          male_actors: [],
          actors: female_actors(doc),
          collection: collection,
          collection_tag: site_config.collection_tag,
          title: title(doc),
          id: search_string.gsub(normalised_title, "") # TODO: This doesn't work some times
        )
      end

      # @param [Nokogiri::XML::NodeSet] doc
      # @return [String]
      def title(doc)
        doc.css(".scene-info div").first.css("h1").text.strip
      end

      # @param [Nokogiri::XML::NodeSet] doc
      # @return [Array[String]]
      def female_actors(doc)
        doc.css(".scene-info .link-list-with-commas a").map { |x| x.text.strip }.sort
      end

      # @param [XxxRename::SiteClients::QueryGenerator::Base::SearchParameters] match
      # @return [String]
      def make_url(match)
        File.join(
          URL_MAPPER[match[:collection]],
          "video",
          match[:title] + match[:id].to_s
        )
      end
    end
  end
end
