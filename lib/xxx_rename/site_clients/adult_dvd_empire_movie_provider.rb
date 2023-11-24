# frozen_string_literal: true

require "httparty"
require "nokogiri"
require "xxx_rename/constants"
require "xxx_rename/data/scene_data"

module XxxRename
  module SiteClients
    class AdultDvdEmpireMovieProvider
      include Utils
      include HTTParty

      base_uri "https://www.adultdvdempire.com"
      DVD_SEARCH_ENDPOINT = "/dvd/search"
      RELEASE_YEAR_REGEX = /\((?<year>\d{4})\)/x.freeze

      def initialize(movie_name:, studio:)
        @movie_name = movie_name
        @studio = studio

        self.class.logger(XxxRename.logger, :debug)
        self.class.headers(Constants::DEFAULT_HEADERS)
      end

      def fetch
        links = find_matching_movies
        fetch_movies(links).find { |x| x.name.n_match?(movie_name) && x.studio.n_substring_either?(studio) }
      end

      private

      attr_reader :movie_name, :studio

      # @param [Array<String>] links
      def fetch_movies(links)
        links.map { |x| fetch_movie_doc(x) }
             .map.with_index { |x, idx| create_movie_hash(x, links[idx]) }
      end

      # @param [Nokogiri::HTML4::Document] doc
      # @return [Data::SceneMovieData]
      # noinspection RubyMismatchedReturnType
      def create_movie_hash(doc, url)
        hash = {}.tap do |h|
          h[:name] = name(doc)
          h[:date] = date(doc) if date(doc)
          h[:url] = "#{self.class.base_uri}#{url}"
          h[:front_image] = front_image!(doc)
          h[:back_image] = back_image(doc) if back_image(doc)
          h[:studio] = studio_name(doc)
          h[:synopsis] = synopsis(doc) if synopsis(doc)
        end
        Data::SceneMovieData.new(hash)
      end

      # @param [Nokogiri::HTML4::Document] doc
      def name(doc)
        doc.css(".movie-page__heading__title").children.first&.text&.strip
      end

      # @param [Nokogiri::HTML4::Document] doc
      # @return [Time, NilClass]
      def date(doc)
        release_year = doc.css(".movie-page__heading__movie-info small").text.strip
        match = release_year.match(RELEASE_YEAR_REGEX)
        if match.nil?
          XxxRename.logger.warn "[NO DATE PARSED] #{movie_name}"
          return
        end

        Time.strptime(match[:year], "%Y").utc
      end

      # @param [Nokogiri::HTML4::Document] doc
      # @return [String]
      def front_image!(doc)
        doc.at_css("#Boxcover #front-cover").attr("data-href")
      end

      # @param [Nokogiri::HTML4::Document] doc
      # @return [String, NilClass]
      def back_image(doc)
        doc.css("#Boxcover #back-cover").map { |x| x.attr("href") }.first
      end

      # @param [Nokogiri::HTML4::Document] doc
      def studio_name(doc)
        doc.css(".movie-page__heading__movie-info a")
           .find { |x| x.attr("label").downcase == "studio" }
           .text.strip
      end

      # @param [Nokogiri::HTML4::Document] doc
      # @return [String, NilClass]
      def synopsis(doc)
        doc.css("#synopsis-container p").text.strip.presence
      end

      # @param [String] link
      # @return [Nokogiri::HTML4::Document]
      def fetch_movie_doc(link)
        resp = handle_response!(return_raw: true) { self.class.get(link, headers: Constants::DEFAULT_HEADERS) }
        Nokogiri::HTML resp.parsed_response
      end

      # @return [Array<String>]
      def find_matching_movies
        doc = search_results
        links = doc.css(".product-details .item-title a")
                   .select { |x| x.attr("title").strip.n_match?(movie_name) } # Select all movies with the matching name
                   .map { |x| x.attr("href") } # Get the link of the movies
        XxxRename.logger.debug "[MOVIE RESULTS n=#{links.length}]\n#{links.join("\n")}"
        links
      end

      # @return [Nokogiri::HTML4::Document]
      def search_results
        resp = handle_response!(return_raw: true) do
          self.class.get(DVD_SEARCH_ENDPOINT,
                         query: { q: movie_name, exactMatch: movie_name },
                         headers: Constants::DEFAULT_HEADERS)
        end
        Nokogiri::HTML resp.parsed_response
      end
    end
  end
end
