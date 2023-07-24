# frozen_string_literal: true

require "xxx_rename/constants"
require "xxx_rename/data/file_pre_processor_rule"
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
      # noinspection RubyMismatchedReturnType
      def generate!
        config_hash = make_config_hash
        valid_config = validate_download_filters!(config_hash)
        Data::Config.new(valid_config)
      end

      # Step 1: Get the base configuration hash with default values
      def default_config
        {
          c00: "[String] Path to store all generated files",
          "generated_files_dir" => generated_files_dir,
          c01: "Configuration to hook into your Stash App",
          "stash_app" => {
            c00: "[String] URL path where your Stash App is hosted",
            c01: "e.g. http://localhost:9999",
            "url" => "",
            c02: "[String] Optional token if your Stash App is password protected",
            "api_token" => nil
          },
          c02: "Global configurations",
          "global" => {
            c000: "Some prefixes are optional and will not be inserted into",
            c001: "the generated filename if the value is empty",
            c00: "[String] Prefix to identity female actors in a filename",
            "female_actors_prefix" => "[F]",
            c01: "[String] Prefix to identity male actors in a filename",
            "male_actors_prefix" => "[M]",
            c02: "[String] Prefix to identity actors in a filename",
            c03: "This will be used as a fallback if xxx_rename is not able",
            c04: "to identify the genders of all actors in a scene",
            "actors_prefix" => "[A]",
            c05: "[String] Prefix to identity scene title in a filename",
            "title_prefix" => "[T]",
            c06: "[String] Prefix to identity scene ID in a filename",
            "id_prefix" => "[ID]",
            c07: "[List] Template to use to generate the filename",
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
          c03: "Individual site configuration. Use this to configure templates to parse filename",
          c04: "output_format List[String]: List of templates that will be used to generate",
          c05: "the output filename. This will take precedence over output_format defined in",
          c06: "global.output_format. If none of the templates defined here are applicable,",
          c07: "xxx_rename will fallback to use the templates defined in global.output_format",
          c08: "file_source_format List[String]: List of templates that will be used to generate",
          c09: "the search params to use search the site client. To ensure maximum correctness,",
          c10: "try to pass in %actors and %title.",
          c11: "collection_tag [String]: This is a tag unique to each site client that xxx_rename",
          c12: "can later reuse to identify the site client from the generated filename.",
          c13: "database [String] Some site clients lack any search functionality whatsoever.",
          c14: "So in order for xxx_rename to work properly, it needs to do a one-time scraping",
          c15: "to get all the scenes from a site and store all the scene details in the file",
          c16: "defined in database value. It is recommended to leave the value to its default",
          c17: "value",
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
              "deeper" =>
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "DEE" },
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
                  "collection_tag" => "JJ" },
              "manuel_ferrara" =>
                { "output_format" => [],
                  "file_source_format" => [],
                  "collection_tag" => "MNF" },
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
                  c00: "Connection to Stash-Box requires authentication. You need to pass in",
                  c01: "either your username + password or api_token. If none of the attributes",
                  c02: "are provided, xxx_rename will raise an error.",
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
                { "output_format" => [], "file_source_format" => [], "collection_tag" => "WI" } },
          c18: "List[Hash{regex->with}]",
          c19: "Provide a list of custom rules to preprocess a file",
          c20: "Each hash should contain two keys:",
          c21: "regex: A valid regex that will be used to create a rule",
          c22: "with: A value that you want to replace the match with",
          c23: "By default, the app will always use these rule(s) for pre-processing:",
          c24: "1. Replace any non-ASCII value (e.g. emojis) with blank strings",
          "file_pre_process" => []
        }
      end

      private

      attr_reader :options, :yaml

      def make_config_hash
        config_file = read_config_file_or_abort!
        override_from_file = config_file.deeper_merge(default_config)
        override_from_options = override_flags_from_options(override_from_file)
        deep_merged = override_from_options.deeper_merge(override_from_file)
        inject_defaults(deep_merged)
      end

      def inject_defaults(hash)
        hash.tap do |h|
          rules = [].concat(Data::FilePreProcessorRule::DEFAULT_RULES)
          rules.concat(h["file_pre_process"])
          h["file_pre_process"] = rules
        end
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
          YAML.dump(default_config).each_line do |l|
            if l.match(/:c(\d+)?:/)
              # Removes hash key(c00) from the string
              # Adds a # in front of the string
              l.sub!(/:c(\d+)?:/, "#")
              # Removes " from the beginning of the line
              l.sub!(/(^\s*# )["']/, '\1')
              # Removes " from the end of the line
              l.sub!(/["']\s*$/, "")
            end
            f.puts l
          end
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
