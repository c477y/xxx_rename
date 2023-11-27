# frozen_string_literal: true

module XxxRename
  module SiteClients
    class Goodporn < Base
      site_client_name :goodporn

      base_uri "https://goodporn.to"
      SCENE_ENDPOINT = "/videos"
      TAG = "GoodPorn"

      # @param [String] filename
      # @param [Data::ParsedSceneData] parsed_scene_data
      # @param [Boolean] unprocessed
      def search(filename, parsed_scene_data:, unprocessed:)
        if parsed_scene_data.blank? || unprocessed
          XxxRename.logger.trace "[#{TAG}] Searching using original downloaded filename strategy"
          scene_stub = scene_stub_from_filename!(filename)
          XxxRename.logger.trace "[#{TAG}] Generated stub: #{scene_stub}"
          search_using_scene_stub(scene_stub)
        else
          search_using_scene_data(parsed_scene_data)
        end
      end

      private

      # @param [String] stub
      # @return [Data::SceneData]
      # noinspection RubyMismatchedReturnType
      def search_using_scene_stub(stub)
        path = File.join(SCENE_ENDPOINT, stub)
        doc = doc(path)
        GoodPornHTMLParser.new(self, doc, abs_path(path)).to_scene_data
      end

      #
      # Original file format is "collection-title-date_res.mp4"
      # res is the resolution of the video e.g. 720p, 1080p
      # e.g. baby-got-boobs-make-it-up-to-my-dick-02-09-2012_720p.mp4
      # @param [String] filename
      # @return [String, nil]
      def scene_stub_from_filename!(filename)
        first = File.basename(filename, ".*").split("_").first
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, filename) unless first.present?

        first
      end

      # @param [Data::ParsedSceneData] parsed_scene_data
      def search_using_scene_data(parsed_scene_data)
        if parsed_scene_data.collection.present? && parsed_scene_data.date_released.present?
          XxxRename.logger.trace "[#{TAG}] Generating scene stub using title, collection and date_released"
          # We can generate the original scene stub using the collection, title and date_released
          scene_stub = "#{parsed_scene_data.collection} #{parsed_scene_data.title} #{parsed_scene_data.date_released.strftime("%m %d %Y")}"
                       .downcase
                       .gsub(/[^\w\s]/, "")
                       .gsub(/\s+/, "-")
          XxxRename.logger.trace "[#{TAG}] Generated stub: #{scene_stub}"
          search_using_scene_stub(scene_stub)
        elsif parsed_scene_data.actors.present?
          XxxRename.logger.trace "[#{TAG}] Searching GoodPorn site search function"
          parsed_scene_data.actors.each { |x| XxxRename.config.actor_helper.auto_fetch!(x) }

          female_actors = parsed_scene_data.actors.select { |x| XxxRename.config.actor_helper.female?(x) }
          XxxRename.logger.trace "[#{TAG}] Identified performers (#{female_actors.join(",")}) as female"
          search_str = "#{parsed_scene_data.title} #{female_actors.join(" ")}"

          XxxRename.logger.trace "[#{TAG}] Generated search query: #{scene_stub}"
          search_using_site_search!(parsed_scene_data, search_str)
        else
          msg = "GoodPorn search needs (title, collection and date_released) or (title and actors)" \
            "to search the site client"
          raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_CUSTOM, msg)
        end
      end

      # @param [Data::ParsedSceneData] parsed_scene_data
      # @param [String] search_str
      def search_using_site_search!(parsed_scene_data, search_str)
        escaped_quote = CGI.escape("\"")
        path = "/search/#{escaped_quote}#{search_str.gsub("\s", "-")}#{escaped_quote}"
        doc = doc(path)
        match = doc.css("#list_videos_videos_list_search_result_items .item .thumb-link")
                   .find { |x| x.attr("title").strip.n_substring?(parsed_scene_data.title) }
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, search_str) if match.nil?

        stub = match.attr("href")
                    .gsub(self.class.base_uri, "")
                    .gsub(SCENE_ENDPOINT, "")

        XxxRename.logger.trace "[#{TAG}] Found search result. Processing link #{stub}"
        search_using_scene_stub(stub)
      end

      def abs_path(link)
        self.class.base_uri + link
      end

      class GoodPornHTMLParser
        include Utils

        # @param [Nokogiri::HTML4::Document] doc
        def initialize(site_client, doc, scene_link)
          @site_client = site_client
          @doc = doc
          @scene_link = scene_link
        end

        def to_scene_data
          scene = {}.tap do |h|
            h[:collection] = collection
            h[:collection_tag] = original_site_prefix
            h[:title] = title
            h[:date_released] = release_date if release_date
            h[:description] = description
            h[:scene_link] = scene_link
          end
          scene.merge!(site_client.send(:actors_hash, actors))
          Data::SceneData.new(scene)
        end

        private

        attr_reader :site_client, :doc, :scene_link

        def description
          description_doc = doc.css(".info .item").select { |x| x.text.strip.start_with?("Description:") }.first

          if description_doc.nil?
            XxxRename.logger.debug "[WARN] No description parsed from scene #{path}"
            ""
          end

          description_doc.text.gsub("Description:", "").strip
        end

        # @return [Array[String]]
        def actors
          actor_doc = doc.css(".info .item").select { |x| x.text.strip.start_with?("Models:") }.first
          if actor_doc.nil?
            XxxRename.logger.debug "[WARN] No actors parsed from scene #{path}"
            return []
          end

          actors = actor_doc.css("a").map { |x| x.text.strip }.sort
          actors.each { |x| XxxRename.config.actor_helper.auto_fetch!(x) }
          actors
        end

        # @return [String]
        def title
          title_text_hash["title"]
        end

        # @return [String]
        def release_date
          title_text_hash["date"].presence
        end

        # @return [String]
        def collection
          title_text_hash["network_name"]
        end

        def title_text_hash
          @title_text_hash ||=
            begin
              split_text = doc.css(".content .headline h1").text.strip.split("-")

              hash = {}
              hash["network_name"] = split_text.first.strip.presence || "GoodPorn"
              hash["date"] = case split_text.last
                             when %r{\d{2}/\d{2}/\d{4}}
                               parse_time(split_text.last.strip, "%m/%d/%Y")
                             when /\d{8}/
                               parse_time(split_text.last.strip, "%m%d%Y")
                             end
              hash["title"] = split_text[1..-2].join("-").strip
              hash
            end
        end

        def channel
          channel_doc = doc.css(".info .item").select { |x| x.text.strip.start_with?("Channel:") }.first

          if channel_doc.nil?
            XxxRename.logger.debug "[WARN] No channel parsed from scene #{path}"
            return "GoodPorn"
          end

          channel_doc.text.gsub("Channel:", "").strip
        end

        def original_site_prefix
          case channel.normalize
          when "babes" then XxxRename.config.site.babes.collection_tag
          when "brazzers" then XxxRename.config.site.brazzers.collection_tag
          when "digitalplayground" then XxxRename.config.site.digital_playground.collection_tag
          when "mofos" then XxxRename.config.site.mofos.collection_tag
          when "realitykings" then XxxRename.config.site.reality_kings.collection_tag
          when "twistys" then XxxRename.config.site.twistys.collection_tag
          else "gp"
          end
        end
      end
    end
  end
end
