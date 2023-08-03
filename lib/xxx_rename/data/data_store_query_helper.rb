# frozen_string_literal: true

module XxxRename
  module Data
    # A Helper class that provides an easy to use interface to
    # query the scene datastore. It checks for all the indexes
    # supported by the scene datastore and returns the matching
    # scene data from the datastore
    class DataStoreQueryHelper
      # @param [XxxRename::Data::SceneDatastoreQuery] datastore
      def initialize(datastore)
        @datastore = datastore
      end

      # The search strategy will rely on multiple queries
      # 1. If absolute path is provided, search using abs path
      # 2. If basename is provided, search using basename
      # 3. If both 1 & 2 fail, check with scene data
      # 4. If collection_tag & id exist in scene_data, search using that
      # 5. If collection & title exist in scene_data, search using that
      # 6. If title & actors exist in scene data, search using that
      # 7. If all lookups fail, return nil
      # @param [XxxRename::Data::SceneData] scene_data
      # @param [String] basename
      # @param [String] absolute_path
      def find(scene_data, basename: nil, absolute_path: nil)
        find_by_abs_path(absolute_path) ||
          find_by_base_filename(scene_data, basename) ||
          find_by_collection_tag_and_id(scene_data.collection_tag, scene_data.id) ||
          find_by_collection_and_title(scene_data.collection, scene_data.title) ||
          find_by_actors_and_title(scene_data)
      end

      private

      def find_by_abs_path(absolute_path)
        return unless absolute_path && (result = datastore.find_by_abs_path?(absolute_path))

        result
      end

      def find_by_base_filename(scene_data, basename)
        return unless basename && (results = datastore.find_by_base_filename?(basename))

        results.find do |result_scene_data|
          eq_check_arr = []
          eq_check_arr << (result_scene_data.title.normalize == scene_data.title.normalize) if scene_data.title.presence
          eq_check_arr << (result_scene_data.collection.normalize == scene_data.collection.normalize) if scene_data.collection.presence
          eq_check_arr.any?
        end
      end

      def find_by_collection_tag_and_id(collection_tag, id)
        return unless collection_tag.presence &&
                      id.presence &&
                      (result = datastore.find(id: id, collection_tag: collection_tag)&.first)

        result
      end

      def find_by_collection_and_title(collection, title)
        return unless collection.presence &&
                      title.presence &&
                      (result = datastore.find(collection: collection, title: title)&.first)

        result
      end

      def find_by_actors_and_title(scene_data) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        return unless scene_data.actors.presence &&
                      scene_data.actors.length.positive? &&
                      scene_data.title.presence &&
                      (results = datastore.find(actors: scene_data.actors, title: scene_data.title))

        return results.first if results.length == 1

        results.find do |result_scene_data|
          eq_check_arr = []
          eq_check_arr << (result_scene_data.id.normalize == scene_data.id.normalize) if scene_data.id.presence
          eq_check_arr << (result_scene_data.collection.normalize == scene_data.collection.normalize) if scene_data.collection.presence
          eq_check_arr << (result_scene_data.collection_tag.normalize == scene_data.collection_tag.normalize) if scene_data.collection_tag.presence
          eq_check_arr.any?
        end
      end

      attr_reader :datastore
    end
  end
end
