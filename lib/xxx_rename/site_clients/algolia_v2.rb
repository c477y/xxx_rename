# frozen_string_literal: true

require "algolia"

require "xxx_rename/site_clients/algolia_common"

module XxxRename
  module SiteClients
    class AlgoliaV2 < Base
      include AlgoliaCommon
      CDN_BASE_URL = "https://transform.gammacdn.com"

      def client(refresh: false)
        if refresh
          XxxRename.logger.debug "Refreshing Algolia Token...".colorize(:blue)

          @client = nil
          @scenes_index = nil
          @movies_index = nil
          @actor_index = nil
        end

        @client = client! if @client.nil?

        @client
      end

      def scenes_index
        @scenes_index ||= client.init_index(self.class::SCENES_INDEX_NAME)
      end

      def movies_index
        @movies_index ||= client.init_index(self.class::MOVIES_INDEX_NAME)
      end

      def actors_index
        @actors_index ||= client.init_index(self.class::ACTORS_INDEX_NAME)
      end

      def fetch_scenes_from_api(str)
        with_retry { scenes_index.search(str, default_query)&.[](:hits) }
      end

      def fetch_actor_from_api(str)
        with_retry { actors_index.search(str)&.[](:hits) }
      end

      private

      def client!
        Algolia::Search::Client.new(algolia_config, logger: XxxRename.logger)
      end

      def algolia_config
        params = algolia_params!(@site_url)
        algolia_config = Algolia::Search::Config.new(application_id: params.application_id,
                                                     api_key: params.api_key)
        algolia_config.set_extra_header("Referer", @site_url)
        algolia_config
      end

      def with_retry(current_attempt: 1, max_attempts: 5, &block)
        if current_attempt > max_attempts
          raise XxxRename::Errors::FatalError, "Retry exceeded #{self.class.name} ran exceeded retry attempts #{max_attempts}"
        end

        block.call
      rescue Algolia::AlgoliaHttpError => e
        case e.code
        when 429
          XxxRename.logger.error "[RATE LIMIT EXCEEDED] Sleeping for 3 minutes. Cancel to run the app at a different time."
          6.times do |counter|
            sleep(30)
            XxxRename.logger.info "[SLEEP ELAPSED] #{counter * 30}s"
          end
        else
          XxxRename.logger.error "#{e.class}: code:#{e.code} message:#{e.message}"
        end
        client(refresh: true)
        with_retry(current_attempt: current_attempt + 1, max_attempts: max_attempts, &block)
      end

      def default_query
        {
          attributesToRetrieve: %w[clip_id title actors release_date description
                                   network_name movie_id movie_title directors sitename pictures],
          hitsPerPage: 50
        }
      end

      def default_facet_filters
        %w[upcoming:0 content_tags:straight]
      end

      def find_matched_scene!(search_results, match)
        scenes = search_results.reject { |x| x[:release_date].nil? }
                               .uniq { |x| x[:clip_id] }
                               .select { |x| actors_contained?(match.actors, x[:actors]) }
                               .select { |x| x[:title].normalize.start_with?(match.title.normalize) }

        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, match.title) if scenes.length != 1

        make_scene_data(scenes.first)
      end

      def make_scene_data(scene) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        hash = {}.tap do |h|
          h[:female_actors] = female_actors(scene)
          h[:male_actors] = male_actors(scene)
          h[:actors] = female_actors(scene) + male_actors(scene)
          h[:collection] = scene[:network_name]&.strip&.titleize
          h[:collection_tag] = site_config.collection_tag
          h[:title] = scene[:title]&.strip

          # Optional attributes
          h[:id] = scene[:clip_id].to_s
          h[:date_released] = date_released(scene[:release_date])
          director = scene[:directors].map { |d_hash| d_hash[:name] }&.first
          h[:director] = director if director
          h[:description] = scene[:description] if scene[:description]
          h[:scene_link] = "#{@site_url}/en/video/#{scene[:sitename]}/#{slug(scene[:title])}/#{scene[:clip_id]}"
          cover = scene.dig(:pictures, :nsfw, :top, :"1920x1080") || scene.dig(:pictures, :resized)
          h[:scene_cover] = "#{CDN_BASE_URL}#{cover}"
          movie_hash = movie_details(scene[:movie_id]) || nil
          h[:movie] = movie_hash unless movie_hash.nil?
        end

        Data::SceneData.new(hash)
      end

      def find_movie(movie_id)
        options = {
          filters: "movie_id:#{movie_id}",
          attributesToRetrieve: %w[movie_id title description date_created
                                   studio_name directors network_name
                                   url_title cover_path],
          hitsPerPage: 1
        }
        with_retry { movies_index.search("", options)&.[](:hits)&.first }
      end

      def movie_details(movie_id)
        return movies[movie_id] if movies.key?(movie_id)

        movie = find_movie(movie_id)
        return if movie.nil?

        movie_hash = {}.tap do |h|
          h[:name] = movie[:title]&.strip&.titleize
          date = date_released(movie[:date_created])
          h[:date] = date if date
          h[:url] = URI.join(@site_url, "/en/movie/", "#{movie[:url_title]}/", (movie[:movie_id]).to_s).to_s
          h[:front_image] = "#{self.class::CDN_BASE_URL}/movies#{movie[:cover_path]}_front_400x625.jpg?width=900&height=1272&format=webp"
          h[:back_image] = "#{self.class::CDN_BASE_URL}/movies#{movie[:cover_path]}_back_400x625.jpg?width=900&height=1272&format=webp"
          h[:studio] = movie[:network_name]&.strip
          h[:synopsis] = movie[:description]
        end

        movies[movie_id] = movie_hash
        movie_hash
      end

      def female_actors(resp)
        resp[:actors]
          .select { |actor| actor[:gender] == "female" }
          .map { |hash| hash[:name] }
          .map(&:strip)
          .sort
      end

      def male_actors(resp)
        resp[:actors]
          .select { |actor| actor[:gender] == "male" }
          .map { |hash| hash[:name] }
          .map(&:strip)
          .sort
      end

      def date_released(str, format = "%Y-%m-%d")
        Time.strptime(str.strip, format)
      rescue ArgumentError => e
        XxxRename.logger.error "[DATE PARSING ERROR] #{e.message}"
        nil
      end

      def movies
        @movies ||= {}
      end
    end
  end
end
