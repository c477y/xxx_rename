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
        fetch_details_from_html(url)
      end

      private

      # @param [String] url
      # @return [Hash, NilClass]
      def fetch_details_from_html(url)
        XxxRename.logger.debug "Scraping data from #{url.to_s.colorize(:blue)}"
        web_resp = HTTParty.get(url, follow_redirects: false)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, url) unless web_resp.code == 200

        search_string = url.split("/").last
        parse_scene_details(web_resp.body, search_string)
      end

      # @param [Nokogiri::HTML::Document] body
      # @param [String] search_string
      # @return [Hash, NilClass]
      def parse_scene_details(body, search_string)
        doc = Nokogiri::HTML(body)
        normalised_title = title(doc).downcase.gsub("-", "").gsub(/['"“”‘’„]/, "-").gsub(/[^\s\w-]/, "").gsub(/\s{2,}/, " ").gsub(
          /\s/, "-"
        )
        Data::SceneData.new(
          female_actors: female_actors(doc),
          male_actors: [],
          actors: female_actors(doc),
          collection: collection(doc),
          collection_tag: site_config.collection_tag,
          title: title(doc),
          id: search_string.gsub(normalised_title, ""), # TODO: This doesn't work some times
          date_released: nil
        )
      end

      # @param [Nokogiri::XML::NodeSet] doc
      # @return [String]
      def title(doc)
        doc.css(".t2019-stitle").text.strip
      end

      # @param [Nokogiri::XML::NodeSet] doc
      # @return [Array[String]]
      def female_actors(doc)
        doc.css("#t2019-models").css(".badge").map { |x| x.text.strip }.sort
      end

      # @param [Nokogiri::XML::NodeSet] doc
      # @return [String]
      def collection(doc)
        doc.css("#navigation").css(".my-0").css("a").map { |x| x["alt"] }.first
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
