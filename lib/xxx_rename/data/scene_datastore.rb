# frozen_string_literal: true

require "pstore"
require "benchmark"
require "pathname"

require "xxx_rename/data/query_interface"

module XxxRename
  module Data
    DEFAULT_STORE_FILE = "xxx_rename_datastore.store"

    METADATA_ROOT = "_m_"
    REGISTERED_FILE_PATHS_PREFIX = "_sp_"

    RecordStatus = Struct.new(:key, :scene_saved, :missing_keys, :conflicting_indexes, :expected_filename_key, keyword_init: true) do
      def valid?
        scene_saved && missing_keys.empty? && conflicting_indexes.empty?
      end

      def errors
        self
      end
    end

    class SceneDatastore
      attr_reader :store

      def initialize(dir, name = DEFAULT_STORE_FILE)
        path = File.join(dir, name)
        XxxRename.logger.info "#{"[DATASTORE INIT]".colorize(:green)} #{path} #{name}"

        @store = PStore.new path
      end
    end

    class SceneDatastoreQuery < QueryInterface
      include FileUtilities

      # @param [XxxRename::Data::SceneData] scene_data
      # @raise [UniqueRecordViolation] is key already exists in the DB
      def create!(scene_data, force: false)
        benchmark("create!") do
          semaphore.synchronize do
            store.transaction do
              unless force
                existing_record = store.fetch(scene_data.key, nil)
                raise UniqueRecordViolation, existing_record if existing_record
              end

              store[scene_data.key] = scene_data
              create_indexes(scene_data.key, scene_data)
              scene_data.key
            end
          end
        end
      end

      # Find a scene using one of
      # 1. collection_tag && id
      # 2. collection_tag && title
      # 3. title && actors
      #
      # @param [String] title
      # @param [Array[String]] actors
      # @param [String] collection_tag
      # @param [String] id
      def find(id: nil, collection_tag: nil, title: nil, actors: nil)
        param = { id: id, collection_tag: collection_tag, title: title, actors: actors }.reject { |_k, v| v.nil? }
        benchmark("find #{param}") do
          validate_type_params!(id: id, collection_tag: collection_tag, title: title, actors: actors)
          semaphore.synchronize do
            store.transaction(read_only: true) do
              keys = fetch_keys?(id: id, collection_tag: collection_tag, title: title, actors: actors)
              keys.map do |key|
                store[key]
              end.compact
            end
          end
        end
      end

      def find_by_abs_path?(path)
        benchmark("find_by_abs_path?") do
          store.transaction(read_only: true) do
            index_key = generate_lookup_key(REGISTERED_FILE_PATHS_PREFIX, path)
            key = store.fetch(index_key, nil)
            return if key.nil?

            store[key]
          end
        end
      end

      def find_by_key?(key)
        benchmark("find_by_key? #{key}") do
          semaphore.synchronize do
            store.transaction(read_only: true) do
              store.fetch(key, nil)
            end
          end
        end
      end

      # @param [XxxRename::Data::SceneData] scene_data
      # @param [String] filename
      def register_file(scene_data, filename, old_filename: nil)
        validate_file_paths!(filename, old_filename: old_filename)
        benchmark("register_file") do
          semaphore.synchronize do
            store.transaction do
              key = scene_data.key
              new_index_key = generate_lookup_key(REGISTERED_FILE_PATHS_PREFIX, filename)
              store[new_index_key] = key

              if old_filename
                old_index_key = generate_lookup_key(REGISTERED_FILE_PATHS_PREFIX, old_filename)
                store.delete(old_index_key)
              end

              new_index_key
            end
          end
        end
      end

      def exists?(key)
        semaphore.synchronize do
          store.transaction(true) do
            store.root?(key)
          end
        end
      end

      alias exist? exists?

      def destroy(scene_data, *filenames)
        benchmark("destroy") do
          semaphore.synchronize do
            store.transaction do
              key = scene_data.key
              store.delete(key)
              destroy_indexes(key, scene_data, *filenames)
              key
            end
          end
        end
      end

      def count
        benchmark("count") do
          semaphore.synchronize do
            store.transaction(true) do
              md5_regex = Regexp.new("^[a-f0-9]{32}$", Regexp::IGNORECASE)

              store.roots.select { |x| x.match?(md5_regex) }.length
            end
          end
        end
      end

      def all
        benchmark("all") do
          semaphore.synchronize do
            store.transaction(true) do
              md5_regex = Regexp.new("^[a-f0-9]{32}$", Regexp::IGNORECASE)

              store.roots.select { |x| x.match?(md5_regex) }.map { |key| store[key] }
            end
          end
        end
      end

      def metadata
        semaphore.synchronize do
          store.transaction(true) do
            store.fetch(METADATA_ROOT, {})
          end
        end
      end

      def update_metadata(hash)
        semaphore.synchronize do
          store.transaction do
            store[METADATA_ROOT] ||= {}
            store[METADATA_ROOT] = store[METADATA_ROOT].merge(hash)
          end
        end
      end

      #
      # Internal method for testing. Is of no use for a user
      #
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/BlockLength
      def valid?(scene_data, filepath: nil)
        validate_file_paths!(filepath, old_filename: nil)

        errors = {
          key: scene_data.key,
          scene_saved: true,
          missing_keys: [],
          conflicting_indexes: {},
          expected_filename_key: nil
        }

        semaphore.synchronize do
          store.transaction(true) do
            key = scene_data.key
            scene = store[key]
            errors[:scene_saved] = false if scene.nil?

            if scene_data.id
              id_index_value = store[generate_lookup_key(scene_data.collection_tag, scene_data.id)]
              errors[:missing_keys] << :id_index if id_index_value.nil?
              errors[:conflicting_indexes][:id_index] = id_index_value if !id_index_value.nil? && id_index_value != key
            end

            # title_index_value = store[generate_lookup_key(scene_data.collection_tag, scene_data.title)]
            # errors[:missing_keys] << :title_index if title_index_value.nil?
            # errors[:conflicting_indexes][:title_index] = title_index_value if !title_index_value.nil? && title_index_value != key

            collection_title_index_value = store[generate_lookup_key(scene_data.collection, scene_data.title)]
            errors[:missing_keys] << :collection_title_index if collection_title_index_value.nil?
            if !collection_title_index_value.nil? && collection_title_index_value != key
              errors[:conflicting_indexes][:collection_title_index] = collection_title_index_value
            end

            # title_actor_index_value = store[generate_lookup_key(scene_data.title, scene_data.actors.sort.join("|"))]
            # errors[:missing_keys] << :title_actors_index if title_actor_index_value.nil? || title_actor_index_value.empty?
            # if title_actor_index_value && !title_actor_index_value.empty? && !title_actor_index_value.include?(key)
            #   errors[:conflicting_indexes][:title_actors_index] = title_actor_index_value
            # end

            if filepath
              filename_value = store[generate_lookup_key(REGISTERED_FILE_PATHS_PREFIX, filepath)]
              unless filename_value
                errors[:missing_keys] << :path
                errors[:expected_filename_key] = sanitize(filepath)
              end
            end

            status = RecordStatus.new(**errors)
            status.valid? ? true : status.errors
          end
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/BlockLength

      private

      def validate_file_paths!(filename, old_filename: nil)
        raise "non absolute path" unless Pathname.new(filename).absolute?

        raise "non absolute path" if old_filename && !Pathname.new(old_filename).absolute?

        raise "file not exist #{filename}" unless valid_file?(filename)

        true
      end

      def validate_type_params!(id:, collection_tag:, title:, actors:)
        raise ArgumentError, "no key provided for lookup" if [id, collection_tag, title, actors].none?

        raise TypeError, "actors: wrong argument type #{actors.class} (expected Array)" if actors && !(actors.is_a? Array)
      end

      #
      # This method id thread unsafe!
      # Always call from a synchronized mutex and within a transaction
      #
      # @param [String] id
      # @param [Array[String]] collection_tag
      # @param [String] title
      # @param [String] actors
      # @return [Array[String]]
      def fetch_keys?(id:, collection_tag:, title:, actors:)
        if collection_tag && id
          [store[generate_lookup_key(collection_tag, id)]]
        elsif collection_tag && title
          [store[generate_lookup_key(collection_tag, title)]]
        elsif title && actors
          store.fetch(generate_lookup_key(title, actors.sort.join("|")), []).to_a
        end
      end

      #
      # Create indexes for a scene for faster lookups.
      # Comes at a cost of increased file size
      # Supported indexes:
      # 1. collection_tag -> id -> key // id index
      # ~~2. collection_tag -> title -> key // title index~~
      # 3. collection -> title -> key // title index
      # ~~4. title + actors -> [keys] // title,actors index~~
      # ** collection_tag -> title & title + actors are not created
      # for performance reasons. They can be supported later if
      # the need arises
      # @param [String] key
      # @param [XxxRename::Data::SceneData] scene_data
      def create_indexes(key, scene_data)
        create_id_index(key, scene_data)
        # create_title_index(key, scene_data)
        create_collection_title_index(key, scene_data)
        # create_title_actors_index(key, scene_data)
      end

      # collection_tag -> id -> key // id index
      # @param [String] key
      # @param [XxxRename::Data::SceneData] scene_data
      def create_id_index(key, scene_data)
        return unless scene_data.id

        index_key = generate_lookup_key(scene_data.collection_tag, scene_data.id)
        store[index_key] = key
      end

      # # collection_tag -> title -> key // title index
      # # @param [String] key
      # # @param [XxxRename::Data::SceneData] scene_data
      # def create_title_index(key, scene_data)
      #   index_key = generate_lookup_key(scene_data.collection_tag, scene_data.title)
      #   store[index_key] = key
      # end

      def create_collection_title_index(key, scene_data)
        index_key = generate_lookup_key(scene_data.collection, scene_data.title)
        store[index_key] = key
      end

      # # title + actors -> [keys] // title,actors index
      # # @param [String] key
      # # @param [XxxRename::Data::SceneData] scene_data
      # def create_title_actors_index(key, scene_data)
      #   index_key = generate_lookup_key(scene_data.title, scene_data.actors.sort.join("|"))
      #
      #   store[index_key] ||= Set.new
      #   store[index_key].add(key)
      # end

      # @param [String] key
      # @param [XxxRename::Data::SceneData] scene_data
      # @param [Array[String]] filenames
      def destroy_indexes(key, scene_data, *filenames)
        destroy_id_index(scene_data)
        # destroy_title_index(scene_data)
        destroy_collection_title_index(key, scene_data)
        # destroy_title_actors_index(key, scene_data)
        destroy_registered_filenames(filenames)
      end

      def destroy_id_index(scene_data)
        return unless scene_data.id

        index_key = generate_lookup_key(scene_data.collection_tag, scene_data.id)
        store.delete(index_key)
      end

      # def destroy_title_index(scene_data)
      #   index_key = generate_lookup_key(scene_data.collection_tag, scene_data.title)
      #   store.delete(index_key)
      # end

      # def destroy_title_actors_index(key, scene_data)
      #   index_key = generate_lookup_key(scene_data.title, scene_data.actors.sort.join("|"))
      #
      #   index_value = store[index_key]
      #   if index_value && index_value.length > 1
      #     index_value.delete(key)
      #   else
      #     store.delete(index_key)
      #   end
      # end

      def destroy_collection_title_index(_key, scene_data)
        index_key = generate_lookup_key(scene_data.collection, scene_data.title)
        store.delete(index_key)
      end

      def destroy_registered_filenames(filenames)
        filenames.map do |file|
          index_key = generate_lookup_key(REGISTERED_FILE_PATHS_PREFIX, file)
          store.delete(index_key)
        end
      end

      def title_actors_index_key(title, actors)
        "<#{sanitize(title)}" \
        "$#{sanitize(actors.sort.join("|"))}" \
        ">"
      end

      def benchmark(opr = "unnamed")
        raise "#benchmark called without block" unless block_given?

        resp = nil
        time = Benchmark.measure { resp = yield }
        XxxRename.logger.debug "#{"[BENCHMARK]".colorize(:cyan)} #{self.class.name}##{opr}: #{time.real.round(3)}s"
        resp
      end
    end
  end
end
