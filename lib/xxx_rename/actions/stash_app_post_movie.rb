# frozen_string_literal: true

require "xxx_rename/actions/base_action"
require "xxx_rename/integrations/stash_app"

module XxxRename
  module Actions
    class StashAppPostMovie < BaseAction
      attr_reader :stash, :config

      def initialize(config)
        super(config)
        @stash = Integrations::StashApp.new(config)
        @stash.setup_credentials!
      end

      def perform(dir, file, search_result)
        scene_data = search_result.scene_data
        return if scene_data.movie.nil?

        post_movie!(dir, file, scene_data)
      rescue XxxRename::Integrations::StashAPIError => e
        XxxRename.logger.error e.message
      end

      private

      def post_movie!(_dir, file, scene_data)
        scene = stash.fetch_scene(file)
        if scene.nil?
          XxxRename.logger.warn "[FILE MISSING ON STASH] #{file}"
          return
        end

        if scene["movies"].find { |x| x.dig("movie", "name") == scene_data.movie.name }
          XxxRename.logger.info "#{"[STASH APP MOVIE NOT UPDATED]".colorize(:yellow)} #{file}"
          return
        end

        studio_id = studio_id(scene_data.movie.studio)
        XxxRename.logger.warn "#{"[NO STUDIO ON STASH]".colorize(:light_red)} #{scene_data.movie.studio}" if studio_id.nil?

        existing_movie = stash.fetch_movie(scene_data.movie.name)
        if existing_movie.nil?
          XxxRename.logger.info "#{"[STASH MOVIE CREATE]".colorize(:green)} #{scene_data.movie.name}"
          movie = stash.create_movie(scene_data, studio_id)
          stash.update_scene(scene["id"], movie["id"])
        else
          XxxRename.logger.info "#{"[STASH MOVIE ASSIGN]".colorize(:green)} #{scene_data.movie.name}"
          stash.update_scene(scene["id"], existing_movie["id"])
        end
      rescue SocketError => e
        XxxRename.logger.error "#{"[SOCKET ERROR #post_movie!]".colorize(:red)} #{e.message}"
        nil
      end

      def studio_id(name)
        stash.fetch_studio(name)&.[]("id")
      end
    end
  end
end
