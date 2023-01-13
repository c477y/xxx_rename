# frozen_string_literal: true

require "nokogiri"
require "xxx_rename/site_clients/query_generator/base"

module XxxRename
  module SiteClients
    class ElegantAngel < Base
      include HTTParty

      base_uri "https://www.elegantangel.com"
      site_client_name :elegant_angel
      OLDEST_PROCESSABLE_MOVIE_YEAR = 2007
      COLLECTION = "Elegant Angel"
      MOVIES_ENDPOINT = "/streaming-elegant-angel-dvds-on-video.html?page=$page$"

      def search(filename)
        refresh_datastore(1) if datastore_refresh_required?
        match = SiteClients::QueryGenerator::Base.generic_generate(filename, source_format)
        lookup_in_datastore!(match)
      end

      def all_scenes_processed?
        all_scenes_processed
      end

      def oldest_processable_date?
        oldest_processable_date
      end

      private

      def lookup_in_datastore!(match)
        msg = "requires both movie title(%collection) and scene title(%title)"
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, msg) if match.nil?

        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, msg) unless match.collection.presence && match.title.presence

        index_key = site_client_datastore.generate_lookup_key(match.collection, match.title)
        scene_data_key = site_client_datastore.find_by_key?(index_key)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, index_key) if scene_data_key.nil?

        scene_data = site_client_datastore.find_by_key?(scene_data_key)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, scene_data_key) if scene_data.nil?

        scene_data
      end

      def all_scenes_processed
        @all_scenes_processed ||= false
      end

      def oldest_processable_date
        @oldest_processable_date ||= false
      end

      def datastore_refresh_required?
        if config.force_refresh_datastore
          XxxRename.logger.info "#{"[FORCE REFRESH]".colorize(:green)} #{self.class.name}"
          true
        else
          false
        end
      end

      def refresh_datastore(page)
        movie_links = movie_links(page)
        @all_scenes_processed = true if movie_links.blank?

        movie_links.map do |path|
          movie_doc = doc(path)
          movie_hash = movie_hash(movie_doc, path)
          if movie_hash[:date].year < OLDEST_PROCESSABLE_MOVIE_YEAR
            @oldest_processable_date = true
            break
          end
          scenes = movie_scenes(movie_doc, movie_hash)
          scenes.map { |scene_data| site_client_datastore.create!(scene_data, force: true) }
        end

        stop_processing? ? true : refresh_datastore(page + 1)
      end

      def stop_processing?
        if all_scenes_processed?
          XxxRename.logger.info "#{"[DATASTORE REFRESH COMPLETE]".colorize(:green)} #{self.class.site_client_name}"
          true
        elsif oldest_processable_date?
          XxxRename.logger.info "#{"[OLDEST PROCESSABLE MOVIE REACHED]".colorize(:green)} #{self.class.site_client_name}"
          true
        else
          false
        end
      end

      def movie_links(page)
        doc = doc(MOVIES_ENDPOINT.gsub("$page$", page.to_s))
        doc.css(".item-grid .grid-item .boxcover")
           .map { |x| x["href"] }
           .uniq
           .map { |x| x.gsub(self.class.base_uri, "") }
      end

      def movie_scenes(doc, movie_hash)
        XxxRename.logger.info "#{"[PROCESSING MOVIE]".colorize(:green)} #{movie_hash[:name]}"

        scenes(doc).map do |scene_doc|
          next if scene_unavailable?(scene_doc)

          hash = {}.tap do |h|
            h[:actors] = scene_doc.css(".scene-performer-names a").map { |x| x.text&.strip }
            h[:collection] = movie_hash[:name]
            h[:collection_tag] = site_config.collection_tag
            h[:title] = scene_doc.at('//a[@class="scene-title"]//h6/text()[last()]')&.text&.strip
            h[:date_released] = movie_hash[:date]
            scene_path = scene_doc.at('//a[@class="scene-title"]/@href').value
            h[:scene_link] = URI.join(self.class.base_uri, scene_path).to_s
            h[:movie] = movie_hash
          end
          XxxRename.logger.info "#{"[PROCESSING SCENE]".colorize(:green)} #{hash[:title]}"
          Data::SceneData.new(hash)
        end.compact
      end

      def scene_unavailable?(scene_doc)
        # scene title is un-clickable
        scene_doc.at('//a[@class="scene-title"]').nil? ||
          # buying scene is disabled
          scene_doc.at('//div[contains(@class, "scene-buy-options")]//button[contains(@class, "disabled")]').present? # scene title is un-clickable
      end

      def scenes(doc)
        doc.xpath('//div[@id="scenes"]//div[@class="scene-details"]').presence ||
          doc.xpath('//div[@id="scenes"]//div[@class="grid-item"]').presence ||
          []
      end

      def movie_hash(doc, path)
        image_css = doc.xpath('//div[@id="viewLargeBoxcoverCarousel"]//div[contains(@class, "carousel-item")]//img/@data-src')
        date_str = doc.xpath('//div[contains(@class, "video-details")]' \
                  '//div[@class="release-date"]' \
                  '//span[contains(text(),"Released")]/../text()').text&.strip
        synopsis = doc.xpath('//div[contains(@class, "video-details")]//div[@class="synopsis"]').text
        {}.tap do |h|
          h[:name] = doc.css(".video-title h1.description").text&.strip
          h[:date] = date_released(date_str, "%b %d, %Y")
          h[:url] = URI.join(self.class.base_uri, path).to_s
          h[:front_image] = image_css.first.text
          h[:back_image] = image_css.last.text if image_css.length == 2
          h[:studio] = "Elegant Angel"
          h[:synopsis] = synopsis if synopsis.presence
        end
      end

      def date_released(str, format = "%Y-%m-%d")
        Time.strptime(str.strip, format)
      rescue ArgumentError => e
        XxxRename.logger.error "[DATE PARSING ERROR] #{e.message}"
        nil
      end

      def doc(path)
        res = handle_response!(return_raw: true) { self.class.get(path) }
        Nokogiri::HTML res.parsed_response
      end
    end
  end
end
