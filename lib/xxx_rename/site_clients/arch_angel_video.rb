# frozen_string_literal: true

require "nokogiri"
require "xxx_rename/constants"
require "xxx_rename/data/site_client_meta_data"
require "xxx_rename/site_clients/query_generator/base"

module XxxRename
  module SiteClients
    class ArchAngelVideo < Base
      include HTTParty

      site_client_name :arch_angel

      base_uri "https://tour.archangelworld.com"

      MOVIES_ENDPOINT = "/dvds/dvds_page_$page$.html"
      COLLECTION = "Arch Angel"

      MovieResult = Struct.new(:url, :details)

      def search(filename)
        refresh_datastore(1) if datastore_refresh_required?
        match = SiteClients::QueryGenerator::Base.generic_generate(filename, source_format)
        lookup_in_datastore!(match)
      end

      def datastore_refresh_required?
        if all_scenes_processed?
          false
        elsif config.force_refresh_datastore
          XxxRename.logger.info "#{"[FORCE REFRESH]".colorize(:green)} #{self.class.name}"
          true
        elsif site_client_datastore.empty?
          XxxRename.logger.info "#{"[EMPTY DATASTORE] Scraping scenes".colorize(:green)} #{self.class.name}"
          true
        else
          datastore_update_required?
        end
      end

      def datastore_update_required?
        # This should check for errors in the metadata
        false
      end

      def refresh_datastore(page = 1)
        XxxRename.logger.info "[PROCESSING PAGE] #{page}"
        movie_links = movie_links(page)

        if movie_links.blank?
          @all_scenes_processed = true
          return
        end

        scene_details = []
        movie_links.map do |movie|
          scene_details.concat(process_scenes(movie))
        end
        scene_details.compact!
        scene_details.map do |scene_data|
          XxxRename.logger.ap scene_data
          site_client_datastore.create!(scene_data, force: true)
        end

        refresh_datastore(page + 1)
      end

      def all_scenes_processed?
        all_scenes_processed
      end

      private

      # @param [MovieResult] movie
      # @return [Array[Data::SceneData]]
      def process_scenes(movie)
        XxxRename.logger.info "[PROCESSING MOVIE] #{movie.details.name}"
        doc = doc(movie.url)
        doc.css(".items .item-episode").map do |scene_doc|
          scene = process_scene(scene_doc)
          Data::SceneData.new(scene.merge({ movie: movie.details.to_h }))
        end
      end

      # @param [Nokogiri::XML::Element] scene_doc
      # @return [Hash]
      def process_scene(scene_doc)
        {}.tap do |h|
          h[:actors] = actors(scene_doc)
          h.merge!(actors_hash(h[:actors]))
          h[:collection] = COLLECTION
          h[:collection_tag] = site_config.collection_tag
          h[:title] = title(scene_doc)
          XxxRename.logger.info "[PROCESSING SCENE] #{h[:title]}"
          h[:date_released] = date_released(scene_doc)
          h[:description] = description(scene_doc)
          h[:scene_link] = scene_link(scene_doc)
          h[:scene_cover] = scene_cover(scene_doc) if scene_cover(scene_doc)
        end
      end

      # @param [Nokogiri::XML::Element] scene_doc
      # @return [String]
      def title(scene_doc)
        scene_doc.at(".item-info h3").text.strip
      end

      # @param [Nokogiri::XML::Element] scene_doc
      # @return [Array[String]]
      def actors(scene_doc)
        scene_doc.css(".item-info .fake-h5 a").map { |x| x.text.strip }
      end

      # @param [Nokogiri::XML::Element] scene_doc
      # @return [Time, NilClass]
      def date_released(scene_doc)
        elem = scene_doc.css(".item-meta li").find { |x| x.text.strip.downcase.start_with?("release date") }
        if elem.nil?
          XxxRename.logger.warn "[NO RELEASE DATE PARSED]"
          return
        end

        release_date = elem.children.last.text.strip
        Time.strptime(release_date, "%b %e, %Y").utc
      end

      # @param [Nokogiri::XML::Element] scene_doc
      # @return [String]
      def description(scene_doc)
        scene_doc.at(".item-info .description").text.strip
      end

      # @param [Nokogiri::XML::Element] scene_doc
      # @return [String]
      def scene_link(scene_doc)
        scene_doc.at(".item-info .item-title-row h3 a").attr("href")
      end

      # @param [Nokogiri::XML::Element] scene_doc
      # @return [String, NilClass]
      def scene_cover(scene_doc)
        image_doc = scene_doc.at(".item-thumbs img")
        return if image_doc.nil?

        %w[src0_3x src0_2x src0_1x]
          .map { |x| image_doc.attr(x) }
          .map { |x| "#{self.class.base_uri}#{x}" }
          .compact.first
      end

      # @param [Integer] page
      # @return [Array[MovieResult]]
      def movie_links(page)
        resp = []
        doc = doc(MOVIES_ENDPOINT.gsub("$page$", page.to_s))
        movies_doc = doc.css(".items .item-portrait")
        movies_doc.map do |movie_doc|
          resp << movie_details(movie_doc)
        end
        resp
      end

      # @param [Nokogiri::XML::NodeSet] movie_doc
      # @return [MovieResult]
      def movie_details(movie_doc)
        movie_hash = {}.tap do |scene_movie_hash|
          # Movie URL
          url = movie_doc.at("a").attr("href")
          # Movie Name
          scene_movie_hash[:name] = movie_doc.at(".item-info h3 a").text.strip
          # Movie Url
          scene_movie_hash[:url] = url
          # Movie Studio
          scene_movie_hash[:studio] = "ArchAngel Video"

          # Front Image
          movie_poster = movie_poster_link(movie_doc)
          if movie_poster.nil?
            XxxRename.logger.warn "[NO POSTER IMAGE SCRAPED] #{key}"
          else
            scene_movie_hash[:front_image] = movie_poster
          end
        end

        MovieResult.new(movie_hash[:url], Data::SceneMovieData.new(movie_hash))
      end

      # @param [Nokogiri::XML::NodeSet] m_doc
      # @return [String, NilClass]
      def movie_poster_link(m_doc)
        image_doc = m_doc.at("img")
        return if image_doc.nil?

        link = %w[src0_3x src0_2x src0_1x].map { |x| image_doc.attr(x) }.compact.first
        return if link.nil?

        link = "#{self.class.base_uri}#{link}" unless link.start_with?(self.class.base_uri)
        link
      end

      def lookup_in_datastore!(match)
        msg = "requires at-least movie-title(%collection) and scene title(%title) or scene title(%title) and actors(%female_actors or %actors)"
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, msg) if match.nil?

        result = query_helper.find(match)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, match.key) if result.nil?

        result
      end

      def all_scenes_processed
        @all_scenes_processed ||= false
      end
    end
  end
end
