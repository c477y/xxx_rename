# frozen_string_literal: true

require "xxx_rename/data/scene_datastore"
require "xxx_rename/data/actors_datastore"
require "xxx_rename/site_client_matcher"

module XxxRename
  module Data
    class Config < Base
      def initialize(attributes)
        super
        # Inject prefix hash set to processed file
        ProcessedFile.prefix_hash_set(prefix_hash)
      end

      attribute :global do
        attribute :female_actors_prefix,  Types::String
        attribute :male_actors_prefix,    Types::String
        attribute :actors_prefix,         Types::String
        attribute :title_prefix,          Types::String
        attribute :id_prefix,             Types::String
        attribute :output_format,         Types::Array.of(Types::String)
      end

      attribute :site do
        attribute? :adult_time,            Data::AdultTimeConfig
        attribute? :babes,                 Data::MgPremiumConfig
        attribute? :blacked,               Data::VixenMediaConfig
        attribute? :blacked_raw,           Data::VixenMediaConfig
        attribute? :brazzers,              Data::MgPremiumConfig
        attribute? :deeper,                Data::VixenMediaConfig
        attribute? :digital_playground,    Data::MgPremiumConfig
        attribute? :elegant_angel,         Data::ElegantAngelConfig
        attribute? :evil_angel,            Data::EvilAngelConfig
        attribute? :goodporn,              Data::GoodpornConfig
        attribute? :jules_jordan,          Data::JulesJordanMediaConfig
        attribute? :manuel_ferrara,        Data::JulesJordanMediaConfig
        attribute? :mofos,                 Data::MgPremiumConfig
        attribute? :naughty_america,       Data::NaughtyAmericaConfig
        attribute? :nf_busty,              Data::NfBustyConfig
        attribute? :reality_kings,         Data::MgPremiumConfig
        attribute? :stash,                 Data::StashDBConfig
        attribute? :tushy,                 Data::VixenMediaConfig
        attribute? :tushy_raw,             Data::VixenMediaConfig
        attribute? :twistys,               Data::MgPremiumConfig
        attribute? :vixen,                 Data::VixenMediaConfig
        attribute? :whale_media,           Data::WhaleMediaConfig
        attribute? :wicked,                Data::WickedConfig
        attribute? :x_empire,              Data::XEmpireConfig
        attribute? :zero_tolerance,        Data::ZeroToleranceConfig
      end

      attribute :stash_app do
        attribute :url,                   Types::String.optional
        attribute :api_token,             Types::String.optional
      end

      attribute :generated_files_dir,     Types::String
      # CLI Flags
      attribute :force_refresh_datastore, Types::Bool
      attribute :force_refresh,           Types::Bool
      attribute :actions,                 Types::Array.of(Types::String)
      attribute? :override_site,          Types::String

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
        @site_client_matcher ||= SiteClientMatcher.new(self, override_site: override_site)
      end
    end
  end
end
