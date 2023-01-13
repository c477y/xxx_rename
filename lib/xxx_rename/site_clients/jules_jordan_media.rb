# frozen_string_literal: true

require "nokogiri"

require "xxx_rename/site_clients/base"
require "xxx_rename/file_utilities"
require "xxx_rename/constants"

module XxxRename
  module SiteClients
    class JulesJordanMedia < Base
      include FileUtilities
      include HTTParty

      headers Constants::DEFAULT_HEADERS

      SCENES_ENDPOINT_TRIAL = "/trial/categories/movies_$page$_d.html"

      def datastore_refresh_required?
        if config.force_refresh_datastore
          XxxRename.logger.info "#{"[FORCE REFRESH]".colorize(:green)} #{self.class.name}"
          true
        else
          false
        end
      end

      def refresh_datastore(page = 1)
        return if all_scenes_processed?

        scenes = get_scenes_from_page(page)
        if scenes.empty?
          XxxRename.logger.info "#{"[DATASTORE REFRESH COMPLETE]".colorize(:green)} #{self.class.site_client_name}"
          @all_scenes_processed = true
          return true
        end

        scenes.map { |scene_data| site_client_datastore.create!(scene_data, force: true) }
        refresh_datastore(page + 1)
      end

      def all_scenes_processed?
        all_scenes_processed
      end

      private

      def lookup_in_datastore!(match)
        msg = "requires both movie title(%collection) and scene title(%title)"
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, msg) if match.nil?

        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, msg) unless collection_key(match) && match.title.presence

        msg = "collection should be either 'julesjordan' or 'manuelferrara' (case-insensitive, spaces allowed)"
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, msg) unless valid_collection?(collection_key(match))

        index_key = site_client_datastore.generate_lookup_key(collection_key(match), match.title)
        scene_data_key = site_client_datastore.find_by_key?(index_key)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, index_key) if scene_data_key.nil?

        scene_data = site_client_datastore.find_by_key?(scene_data_key)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, scene_data_key) if scene_data.nil?

        scene_data
      end

      def collection_key(match)
        config.override_site.presence || match.collection.presence
      end

      def valid_collection?(collection)
        match?(collection, self.class::COLLECTION)
      end

      def all_scenes_processed
        @all_scenes_processed ||= false
      end

      def get_scenes_from_page(page)
        XxxRename.logger.info "#{"[PROCESSING PAGE]".colorize(:green)} #{page}"
        url = SCENES_ENDPOINT_TRIAL.gsub("$page$", page.to_s)
        doc = doc(url)

        all_scenes_urls(doc).map do |link|
          scene_data = make_scene_data(link)
          XxxRename.logger.info "#{"[PROCESSING SCENE]".colorize(:green)} #{scene_data.title}"
          scene_data
        end
      end

      def all_scenes_urls(doc)
        doc.css(".category_listing_wrapper_updates a")
           .map { |x| x["href"] }
           .select { |x| x.include?("/trial/scenes/") }
           .uniq
      end

      def make_scene_data(link)
        endpoint = link.gsub(self.class.base_uri, "")
        doc = doc(endpoint)
        actors_hash = actors_hash(actors(doc))
        movie_hash = movie_hash(doc)
        hash = {}.tap do |h|
          h[:collection] = self.class::COLLECTION
          h[:collection_tag] = site_config.collection_tag
          h[:title] = title(doc)
          h[:id] = nil
          h[:date_released] = date_released(doc)
          h[:movie] = movie_hash unless movie_hash.nil?
        end.merge(actors_hash)
        Data::SceneData.new(hash)
      end

      def title(doc)
        doc.css(".title_bar_hilite").text.strip
      end

      def date_released(doc)
        txt = doc.css(".backgroundcolor_info .update_date").text.strip
        Time.strptime(txt, "%m/%d/%Y")
      end

      def female_actors(actors)
        actors.select { |x| ActorsHelper.instance.female? x }
      end

      def actors(doc)
        doc.css(".backgroundcolor_info .update_models a")
           .map(&:text)
           .map(&:strip)
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

      def doc(endpoint)
        res = handle_response!(return_raw: true) { self.class.get(endpoint) }
        Nokogiri::HTML res.parsed_response
      end

      def processed_movies
        @processed_movies ||= {}
      end
    end
  end
end
