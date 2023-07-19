# frozen_string_literal: true

require "xxx_rename/data/stash_app_scene_fragment"

module XxxRename
  # noinspection RubyMismatchedReturnType
  class StashAppClient

    # @param [Data::Config] config
    def initialize(config)
      @config = config
    end

    def scene_by_fragment
      scene_data = lookup(scene_input)
      return if scene_data.nil?

      print JSON.dump(scene_data.to_stashapp_scene_fragment.to_hash)
    end

    private

    attr_reader :config

    # @param [Data::StashAppSceneFragment] scene
    # @return [Data::SceneData, nil]
    def lookup(scene)
      result = lookup_with_filename?(scene.title)

      return result if result

      abs_path = fetch_scene_path(scene.id)
      return unless abs_path

      lookup_using_absolute_path?(abs_path) || lookup_with_filename?(File.basename(abs_path))
    end

    # @param [String] abs_path
    # @return [Data::SceneData, nil]
    def lookup_using_absolute_path?(abs_path)
      config.scene_datastore.find_by_abs_path?(abs_path)
    end

    # @return [Data::SceneData, nil]
    def lookup_with_filename?(filename)
      config.scene_datastore.find_by_base_filename?(filename)
    end

    #
    # Returns the absolute path of the file belonging to a scene
    # Can return nil if the scene has no filename
    # @return [String, NilClass]
    def fetch_scene_path(scene_id)
      stash_scene = stash.fetch_scene_paths_by_id(scene_id)
      return unless stash_scene

      stash_scene.first
    end

    def stash
      @stash ||=
        begin
          stash = Integrations::StashApp.new(config)
          stash.setup_credentials!
          stash
        end
    end

    # @return [Data::StashAppSceneFragment]
    def scene_input
      query = $stdin.gets
      XxxRename.logger.info query
      Data::StashAppSceneFragment.new(JSON.parse(query))
    end
  end
end
