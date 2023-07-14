# frozen_string_literal: true

require "nokogiri"

require "xxx_rename/site_clients/base"
require "xxx_rename/site_clients/jules_jordan_media"
require "xxx_rename/file_utilities"
require "xxx_rename/constants"

module XxxRename
  module SiteClients
    # julesjordan.com went through a site revamp. At the time of writing
    # this class, manuelferrara.com is still using the old layout. This
    # class should become obsolete once they update manuelferrara.com.
    # For the time being while the site is still using the old layout,
    # this hacky class should provide matchers using the old layout.

    class ManuelFerraraMedia < JulesJordanMedia
      private

      def all_scenes_urls(doc)
        doc.css(".category_listing_wrapper_updates a")
           .map { |x| x["href"] }
           .select { |x| x.include?("/trial/scenes/") }
           .uniq
      end

      def title(doc)
        doc.css(".title_bar_hilite").text.strip
      end

      def date_released(doc)
        txt = doc.css(".backgroundcolor_info .update_date").text.strip
        Time.strptime(txt, "%m/%d/%Y")
      end

      def actors(doc)
        doc.css(".backgroundcolor_info .update_models a")
           .map(&:text)
           .map(&:strip)
      end

      def description(doc)
        doc.css(".update_description").text.strip
      end

      def movie_hash(doc)
        movie_url, movie_name = movie_details(doc)
        return nil if movie_url.nil?

        endpoint = movie_url.gsub(self.class.base_uri, "")
        if processed_movies.key?(endpoint)
          XxxRename.logger.debug "[MOVIE ALREADY PROCESSED] #{movie_name}"
          return processed_movies[endpoint]
        end

        XxxRename.logger.info "#{"[PROCESSING MOVIE]".colorize(:green)} #{movie_name}"
        movie_doc = doc(endpoint)
        h = {
          name: movie_name,
          url: movie_url,
          front_image: movie_doc.at("//div[@class=\"front\"]/a/img/@src0_3x").value,
          back_image: movie_doc.at("//div[@class=\"back\"]/a/img/@src0_3x").value,
          studio: self.class::COLLECTION
        }
        processed_movies[endpoint] = h
        h
      end

      def movie_details(doc)
        node = doc.css(".backgroundcolor_info .update_dvds a")
        return [nil, nil] if node.nil?

        url = node.map { |x| x["href"] }.first
        name = node.map(&:text).map(&:strip)&.first
        [url, name]
      end
    end
  end
end
