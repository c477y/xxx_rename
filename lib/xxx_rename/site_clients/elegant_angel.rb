# frozen_string_literal: true

require "nokogiri"
require "xxx_rename/data/site_client_meta_data"
require "xxx_rename/site_clients/query_generator/base"

module XxxRename
  module SiteClients
    class ElegantAngel < Base
      include HTTParty

      base_uri "https://www.elegantangel.com"
      site_client_name :elegant_angel
      OLDEST_PROCESSABLE_MOVIE_YEAR = 2004
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

      def datastore_refresh_required?
        if oldest_processable_date? || all_scenes_processed?
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

      def refresh_datastore(page)
        movie_links = movie_links(page)

        if movie_links.blank?
          @all_scenes_processed = true
        elsif page == 1
          # noinspection RubyMismatchedArgumentType
          update_metadata(Data::SiteClientMetaData.create(movie_links.first))
        end

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

      private

      def lookup_in_datastore!(match)
        msg = "requires both movie title(%collection) and scene title(%title)"
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, msg) if match.nil?

        result = query_helper.find(match)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, match.key) if result.nil?

        result
      end

      def all_scenes_processed
        @all_scenes_processed ||= false
      end

      def oldest_processable_date
        @oldest_processable_date ||= false
      end

      def datastore_update_required?
        return true if metadata.nil?

        first_link = movie_links(1).first
        metadata.latest_url != first_link
      end

      # noinspection RubyMismatchedArgumentType
      def stop_processing?
        if all_scenes_processed?
          XxxRename.logger.info "#{"[DATASTORE REFRESH COMPLETE]".colorize(:green)} #{self.class.site_client_name}"
          update_metadata(metadata.mark_complete)
          @all_scenes_processed = true
          true
        elsif oldest_processable_date?
          XxxRename.logger.info "#{"[OLDEST PROCESSABLE MOVIE REACHED]".colorize(:green)} #{self.class.site_client_name}"
          update_metadata(metadata.mark_complete)
          @all_scenes_processed = true
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
            h.merge!(actors_hash(h[:actors]))
            h[:collection] = movie_hash[:name]
            h[:collection_tag] = site_config.collection_tag
            h[:title] = scene_doc.css(".scene-title h6").text.strip
            h[:date_released] = movie_hash[:date]
            scene_path = scene_doc.css(".scene-title").map { |x| x["href"] }.first
            h[:scene_link] = URI.join(self.class.base_uri, scene_path).to_s
            h[:scene_cover] = scene_cover(scene_doc) if scene_cover(scene_doc)
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

      def scene_cover(doc)
        doc.css(".scene-preview-container img")&.attr("src")&.value
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
    end
  end
end
