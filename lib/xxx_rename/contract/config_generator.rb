# frozen_string_literal: true

require "xxx_rename/constants"
require "fileutils"

module XxxRename
  module Contract
    class ConfigGenerator
      include XxxRename::FileUtilities
      include SystemConstants

      DEFAULT_CONFIG_FILE = "config.yml"

      def initialize(options)
        @options = options
        generated_files_dir
      end

      # @return [Data::Config]
      def generate!
        config_hash = make_config_hash
        valid_config = validate_download_filters!(config_hash)
        Data::Config.new(valid_config)
      end

      # Step 1: Get the base configuration hash with default values
      def default_config
        {
          "generated_files_dir" => generated_files_dir,
          "stash_app" => {
            "url" => "",
            "api_token" => nil
          },
          "global" => {
            "female_actors_prefix" => "[F]",
            "male_actors_prefix" => "[M]",
            "actors_prefix" => "[A]",
            "title_prefix" => "[T]",
            "id_prefix" => "[ID]",
            "output_format" => [
              # disable line length check for readability
              # rubocop:disable Layout/LineLength
              "%yyyy_mm_dd %id_prefix %id %title_prefix %title %collection_tag %collection %female_actors_prefix %female_actors %male_actors_prefix %male_actors",
              "%yyyy_mm_dd %id_prefix %id %title_prefix %collection_tag %collection %actors_prefix %actors",
              "%yyyy_mm_dd %title_prefix %title %collection_tag %collection %female_actors_prefix %female_actors %male_actors_prefix %male_actors",
              "%yyyy_mm_dd %title_prefix %collection_tag %collection %actors_prefix %actors"
              # rubocop:enable Layout/LineLength
            ]
          },
          "site" =>
            { "adult_time" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "AT" },
              "babes" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "BA" },
              "blacked" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "BL" },
              "blacked_raw" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "BLR" },
              "brazzers" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "BZ" },
              "digital_playground" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "DP" },
              "elegant_angel" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "EL" },
              "evil_angel" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "EA" },
              "goodporn" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "GP" },
              "jules_jordan" =>
                { "output_format" => [],
                  "file_source_format" => [],
                  "collection_tag" => "JJ",
                  "cookie_file" => nil },
              "manuel_ferrara" =>
                { "output_format" => [],
                  "file_source_format" => [],
                  "collection_tag" => "MNF",
                  "cookie_file" => nil },
              "mofos" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "MF" },
              "naughty_america" =>
                { "output_format" => [],
                  "file_source_format" => [],
                  "collection_tag" => "NA",
                  "database" => File.join(generated_files_dir, "naughtyamerica.store") },
              "nf_busty" =>
                { "output_format" => [],
                  "file_source_format" => [],
                  "collection_tag" => "NF",
                  "database" => File.join(generated_files_dir, "nf_busty.store") },
              "reality_kings" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "RK" },
              "stash" =>
                { "output_format" => [],
                  "file_source_format" => [],
                  "username" => nil,
                  "password" => nil,
                  "api_token" => nil,
                  "collection_tag" => "ST" },
              "tushy" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "TU" },
              "tushy_raw" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "TUR" },
              "twistys" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "TW" },
              "vixen" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "VX" },
              "whale_media" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "WH" },
              "wicked" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "WI" },
              "x_empire" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "XM" },
              "zero_tolerance" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "WI" } }
        }
      end

      private

      attr_reader :options, :yaml

      def make_config_hash
        config_file = read_config_file_or_abort!
        override_from_file = config_file.deeper_merge(default_config)
        override_from_options = override_flags_from_options(override_from_file)
        override_from_options.deeper_merge(override_from_file)
      end

      def generated_files_dir
        @generated_files_dir ||=
          begin
            dir = File.join(home_dir, ".config", "xxx_rename", "generated")
            FileUtils.mkpath(dir)
            File.expand_path(dir)
          end
      end

      def save_default_config
        file = File.join(config_file_lookup_dirs[0], DEFAULT_CONFIG_FILE)

        XxxRename.logger.info "-" * 100
        XxxRename.logger.info "Config option not passed to app and no config file detected in the current directory."
        XxxRename.logger.info "Generating a blank configuration file to #{file} This app will now exit."
        XxxRename.logger.info "Check the contents of the file and run the app again to start downloading."
        XxxRename.logger.info "-" * 100

        raise Errors::FatalError, "config file already exists" if valid_file?(file)

        File.open(file, "w") do |f|
          f.write default_config.to_yaml
        end
      end

      # Step 2: Get the configuration hash from the config file, if present
      # This method will raise an error if no config file is present,
      # which is intentional, to allow users to create a config file automatically
      def read_config_file_or_abort!
        return read_yaml!(options["config"], nil) if options["config"]

        config_file_lookup_dirs.each do |dir|
          file = File.join(dir, DEFAULT_CONFIG_FILE)
          next unless valid_file?(file)

          contents = read_yaml!(file, nil) || {}
          return contents
        end

        save_default_config
        raise XxxRename::Errors::SafeExit, "DEFAULT_FILE_GENERATION"
      end

      # Step 3: Override any configuration with the options passed to the CLI
      def override_flags_from_options(config)
        {}.tap do |h|
          h["override_site"] = options["override_site"] if options["override_site"]
          h["global"] = config["global"].merge(**overridden_globals(config["global"]))
          h["force_refresh_datastore"] = options["force_refresh_datastore"] || false
          h["actions"] = options["actions"] || []
          h["force_refresh"] = options["force_refresh"] || false
        end
      end

      def overridden_globals(hash)
        {
          "female_actors_prefix" => override_value(hash["female_actors_prefix"], options["female_actors_prefix"]),
          "male_actors_prefix" => override_value(hash["male_actors_prefix"], options["male_actors_prefix"]),
          "actors_prefix" => override_value(hash["actors_prefix"], options["actors_prefix"]),
          "title_prefix" => override_value(hash["title_prefix"], options["title_prefix"]),
          "id_prefix" => override_value(hash["id_prefix"], options["id_prefix"]),
          "collection_prefix" => override_value(hash["collection_prefix"], options["collection_prefix"])
        }.compact
      end

      def validate_download_filters!(hash)
        contract = Contract::ConfigContract.new(filename_generator: FilenameGenerator).call(hash)
        raise XxxRename::Errors::ConfigValidationError, contract.errors unless contract.errors.empty?

        contract.to_h.transform_keys(&:to_s)
      end

      def override_value(original, override)
        override.nil? ? original : override
      end
    end
  end
end
