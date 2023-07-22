# frozen_string_literal: true

require "nokogiri"
require "pathname"
require "xxx_rename/site_clients/query_generator/naughty_america"

module XxxRename
  module SiteClients
    class NaughtyAmerica < Base
      include HTTParty
      base_uri "https://www.naughtyamerica.com"

      site_client_name :naughty_america
      ACTOR_ENDPOINT = "/pornstar"

      def search(filename)
        resp = SiteClients::QueryGenerator::NaughtyAmerica.generate(filename, source_format)
        case resp
        when String
          search_unprocessed(filename, resp)
        when SiteClients::QueryGenerator::Base::SearchParameters
          search_processed(resp)
        else
          raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, filename)
        end
      end

      def search_processed(scene_data)
        female_actor = scene_data.female_actors.first || scene_data.actors.first
        scenes = fetch_scenes(female_actor)
        scenes.select do |x|
          x.match_processed?(scene_data)
        end.first&.to_struct || raise(Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, scene_data.to_s))
      end

      def search_unprocessed(filename, compressed_scene_title)
        actor = parent_dir(filename)
        scenes = fetch_scenes(actor)
        match = scenes.select { |x| x.match_unprocessed?(compressed_scene_title) }.first&.to_struct

        return match if match

        XxxRename.logger.error "#{actor} - #{compressed_scene_title}"
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, compressed_scene_title)
      end

      # @param [String] actor
      # @return [Array[NaughtyAmericaScene]]
      def fetch_scenes(actor, force = false)
        if force
          XxxRename.logger.debug "Force fetch scene #{actor}"
          fetch_scenes_from_api(actor)
        else
          fetch_scenes_from_cache(actor) || fetch_scenes_from_api(actor)
        end
      end

      def fetch_scenes_from_cache(actor)
        scene_store.transaction(true) do
          scene_store[normalized_actor(actor)]
        end
      end

      def fetch_scenes_from_api(actor)
        scenes = process_actor(actor)
        return if scenes.nil?

        cache_scenes(normalized_actor(actor), scenes)
      end

      def cache_scenes(actor, scenes)
        scene_store.transaction do
          scene_store[actor] = [] unless scene_store[actor]
          existing_actors = scene_store[actor]
          diff_scenes = scenes - existing_actors
          diff_scenes.each do |scene|
            XxxRename.logger.debug "Adding #{scene.title} to cache"
            scene_store[actor] << scene
          end
        end
      end

      def normalized_actor(actor)
        actor.normalize
      end

      def process_actor(actor)
        actor_all_scenes = []
        (1..5).to_a.each { |page| actor_all_scenes.concat(fetch_actors_page(actor, page: page)) }
      rescue Errors::NoMatchError => e
        case e.code
        when NoMatchError::ERR_NO_RESULT
          XxxRename.logger.info "Naughty America does not have an actor named #{actor}"
        when NoMatchError::ERR_NW_REDIRECT
          XxxRename.logger.debug "Page #{e.data} exceeded maximum available pages"
        end
        actor_all_scenes
      end

      def fetch_actors_page(actor, page:)
        doc = fetch_actor_page!(actor, page: page)
        scenes = doc.css(".contain-block").css(".alt-bg").css(".scene-item")
        scenes.map do |scene|
          next if vr?(scene)

          NaughtyAmericaScene.new(
            collection: collection(scene),
            actors: actors(scene),
            date_released: date_released(scene),
            remastered: remastered?(scene),
            title: title(scene),
            id: id(scene)
          )
        end.compact
      end

      def title(scene)
        scene_path(scene).split("-")[..-2].join(" ").humanize
      end

      def id(scene)
        id = scene_path(scene).split("-").last
        Integer(id) ? id.to_s : ""
      end

      def scene_path(scene)
        URI(scene.css("a").first["href"]).path.split("/").last
      end

      def remastered?(scene)
        scene.css("a").any? { |x| x.text.strip.upcase == "REMASTERED HD" }
      end

      def vr?(scene)
        scene.css("a").any? { |x| x.text.strip == "VR" }
      end

      def collection(scene)
        scene.css(".site-title").text.strip
      end

      def actors(scene)
        scene.css(".contain-actors a").map { |x| x.text.strip }
      end

      def date_released(scene)
        Time.strptime(scene.css(".entry-date").text.strip, "%b %d, %Y")
      end

      def parent_dir(filename)
        path = Pathname.new(File.join(Dir.pwd, filename))
        path.dirname.each_filename.to_a.last
      end

      def fetch_actor_page!(actor, page:)
        actor_name_normalised = actor.downcase.gsub("\s", "-")
        endpoint = File.join(ACTOR_ENDPOINT, actor_name_normalised)
        query = { related_page: page }
        XxxRename.logger.debug "API path: #{endpoint}, query: #{query}"
        resp = self.class.get(endpoint, query: query, follow_redirects: false)
        case resp.code
        when 200 then Nokogiri::HTML(resp.body)
        when 301 then raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NW_REDIRECT, page)
        when 404 then raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, actor_name_normalised)
        when 503 then raise SiteClients::Errors::SiteClientUnavailableError, self.class.base_uri
        else raise "Something went wrong #{resp.code}"
        end
      end

      def scene_store
        @scene_store ||= Data::NaughtyAmericaDatabase.new(site_config.database).store
      end

      class NaughtyAmericaScene
        attr_reader :actors, :collection, :date_released, :remastered, :title, :id

        COLLECTION_ABBRS = {
          "americandaydreams" => "add",
          "diaryofananny" => "don",
          "housewife1on1" => "h1on1",
          "ihaveawife" => "ihw",
          "fasttimes" => "ftna",
          "lasluts" => "las",
          "latinadultery" => "lad",
          "momsmoney" => "momo",
          "mrscreampie" => "namcp",
          "mywifeismypornstar" => "mwmp",
          "naughtyamerica" => "nam",
          "naughtyathletics" => "nath",
          "naughtybookworms" => "nbw",
          "naughtyweddings" => "naw",
          "neighboraffair" => "naf",
          "seducedbycougar" => "sbc",
          "watchyourmom" => "natngf",
          "dirtywivesclub" => "nadwc"
        }.freeze

        ACTOR_ABBRS = {
          "mrpete" => %w[mrpete pete],
          "ryandriller" => %w[ryandriller ryan driller]
        }.freeze

        def initialize(collection:, actors:, date_released:, remastered:, title:, id:)
          @collection = collection
          @actors = actors
          @date_released = date_released
          @title = title
          @id = id
          @remastered = remastered
        end

        def condensed_collection
          col = COLLECTION_ABBRS[collection.normalize]
          return col if col

          collection.split(" ").map { |x| x[0, 1] }.join("").downcase
        end

        def female_actors
          actors.select { |x| config.actor_helper.female? x }
        end

        def male_actors
          actors.select { |x| config.actor_helper.male? x }
        end

        def condensed_actor(actor)
          act = ACTOR_ABBRS[actor.normalize]
          return act if act

          [actor.downcase.normalize, actor.split(" ").first&.downcase]
        end

        def remastered?
          remastered
        end

        def match_unprocessed?(condensed_title)
          dup = condensed_title.dup
          dup.slice!(condensed_collection)
          dup.slice!("rem") if remastered?
          actors.each { |x| condensed_actor(x).each { |y| dup.slice!(y) } }
          dup == ""
        end

        def match_processed?(scene_data)
          arity = []
          arity << (scene_data.actors - actors == [])
          arity << (scene_data.collection.normalize == collection.normalize)
          arity << (scene_data.title.normalize == title.normalize) unless scene_data.title.nil? || scene_data.title.empty?
          arity << (scene_data.id == id) unless scene_data.id.nil? || scene_data.id.empty?
          arity.none?(false)
        end

        def to_struct
          actors.each { |x| config.actor_helper.auto_fetch x }

          Data::SceneData.new(
            female_actors: female_actors,
            male_actors: male_actors,
            actors: actors,
            title: title,
            collection: collection,
            collection_tag: "NA",
            id: id,
            date_released: date_released
          )
        end
      end
    end
  end
end
