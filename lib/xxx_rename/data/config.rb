# frozen_string_literal: true

# noinspection RubyMismatchedArgumentType
module XxxRename
  module Data
    class Config < Base
      class SiteConfig < Base
        attribute :output_format, Types::Array.of(Types::String)
        attribute :file_source_format, Types::Array.of(Types::String)
        attribute :collection_tag, Types::String
      end

      class CredentialsConfig < Base
        attribute? :username, Types::String.optional
        attribute? :password, Types::String.optional
        attribute? :cookie_file, Types::String.optional
        attribute? :api_token, Types::String.optional
      end

      class DatabaseConfig < Base
        attribute? :database, Types::String.optional
      end

      def initialize(attributes)
        super

        # Initialise config
        XxxRename.config_set(self)

        # Inject prefix hash set to processed file
        ProcessedFile.prefix_hash_set(prefix_hash)
      end

      ACTIONS = Types::String.enum("sync_to_stash", "log_rename_op")

      attribute :global do
        attribute :female_actors_prefix, Types::String
        attribute :male_actors_prefix, Types::String
        attribute :actors_prefix, Types::String
        attribute :title_prefix, Types::String
        attribute :id_prefix, Types::String
        attribute :output_format, Types::Array.of(Types::String)
      end

      attribute :site do # rubocop:disable Metrics/BlockLength
        attribute? :adult_time, SiteConfig
        attribute? :arch_angel do
          attributes_from SiteConfig
          attributes_from DatabaseConfig
        end
        attribute? :babes, SiteConfig
        attribute? :blacked, SiteConfig
        attribute? :blacked_raw, SiteConfig
        attribute? :brazzers, SiteConfig
        attribute? :deeper, SiteConfig
        attribute? :digital_playground, SiteConfig
        attribute? :elegant_angel do
          attributes_from SiteConfig
          attributes_from DatabaseConfig
        end
        attribute? :evil_angel, SiteConfig
        attribute? :goodporn, SiteConfig
        attribute? :jules_jordan do
          attributes_from SiteConfig
          attributes_from DatabaseConfig
          attributes_from CredentialsConfig
        end
        attribute? :manuel_ferrara do
          attributes_from SiteConfig
          attributes_from DatabaseConfig
          attributes_from CredentialsConfig
        end
        attribute? :mofos, SiteConfig
        attribute? :naughty_america do
          attributes_from SiteConfig
          attributes_from DatabaseConfig
        end
        attribute? :nf_busty do
          attributes_from SiteConfig
          attributes_from DatabaseConfig
        end
        attribute? :reality_kings, SiteConfig
        attribute? :stash do
          attributes_from SiteConfig
          attributes_from CredentialsConfig
        end
        attribute? :tushy, SiteConfig
        attribute? :tushy_raw, SiteConfig
        attribute? :twistys, SiteConfig
        attribute? :vixen, SiteConfig
        attribute? :whale_media, SiteConfig
        attribute? :wicked, SiteConfig
        attribute? :x_empire, SiteConfig
        attribute? :zero_tolerance, SiteConfig
      end

      attribute :stash_app do
        attribute :url, Types::String.optional
        attribute :api_token, Types::String.optional
      end

      attribute :file_pre_process, Types::Array.of(FilePreProcessorRule)
      attribute :generated_files_dir, Types::String
      # CLI Flags
      attribute :force_refresh_datastore, Types::Bool
      attribute :force_refresh, Types::Bool
      attribute :actions, Types::Array.of(ACTIONS)
      attribute? :override_site, Types::String

      # @return [Hash{Symbol->String}]
      def prefix_hash
        {
          female_actors_prefix: global.female_actors_prefix,
          male_actors_prefix: global.male_actors_prefix,
          actors_prefix: global.actors_prefix,
          title_prefix: global.title_prefix,
          id_prefix: global.id_prefix
        }
      end

      # Maps a site collection tag to site's name
      # @return [Hash{String->String}]
      def collection_tag_to_site_client
        @collection_tag_to_site_client ||= {}.tap do |h|
          site.attributes.each_pair do |site_name, site_config|
            h[site_config.collection_tag] = site_name
          end
        end
      end

      #
      # Added to support multi-threaded operations when implemented
      # @return [Mutex]
      def mutex
        @mutex ||= Mutex.new
      end

      # @return [XxxRename::Data::SceneDatastoreQuery]
      def scene_datastore
        @scene_datastore ||=
          begin
            store = Data::SceneDatastore.new(File.join(generated_files_dir, "..")).store
            SceneDatastoreQuery.new(store, mutex)
          end
      end

      # @return [XxxRename::Data::FileRenameOpDatastore]
      def output_recorder
        @output_recorder ||=
          begin
            store = Data::OutputDatastore.new(generated_files_dir).store
            datastore = Data::FileRenameOpDatastore.new(store, mutex)
            datastore.migration_status = 0
            datastore
          end
      end

      # @return [XxxRename::Data::ActorsDatastoreQuery]
      def actors_datastore
        @actors_datastore ||=
          begin
            store = Data::ActorsDatastore.new(File.join(generated_files_dir, "..")).store
            ActorsDatastoreQuery.new(store, mutex)
          end
      end

      def actor_helper
        @actor_helper ||= ActorsHelper.new(actors_datastore, site_client_matcher)
      end

      # @return [XxxRename::SiteClientMatcher]
      def site_client_matcher
        @site_client_matcher ||= SiteClientMatcher.new
      end
    end
  end
end
