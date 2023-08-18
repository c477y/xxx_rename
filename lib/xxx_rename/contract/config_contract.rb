# frozen_string_literal: true

module XxxRename
  module Contract
    class ConfigContract < Dry::Validation::Contract
      include FileUtilities
      option :filename_generator

      SITE_CONFIG = Dry::Schema.JSON do
        required(:collection_tag).value(Types::SanitizedString)
        required(:output_format).value(array[Types::SanitizedString])
        required(:file_source_format).value(array[Types::SanitizedString])
      end

      STASH_CONFIG = Dry::Schema.JSON do
        required(:collection_tag).value(Types::SanitizedString)
        optional(:username).maybe(Types::SanitizedString)
        optional(:password).maybe(Types::SanitizedString)
        optional(:api_token).maybe(Types::SanitizedString)
        required(:output_format).value(array[Types::SanitizedString])
        required(:file_source_format).value(array[Types::SanitizedString])
      end

      NAUGHTY_AMERICA_CONFIG = Dry::Schema.JSON do
        # if database is not provided, it will be created automatically
        optional(:database).filled(Types::SanitizedString)
        required(:collection_tag).value(Types::SanitizedString)
        required(:output_format).value(array[Types::SanitizedString])
        required(:file_source_format).value(array[Types::SanitizedString])
      end

      NF_BUSTY_CONFIG = Dry::Schema.JSON do
        # if database is not provided, it will be created automatically
        optional(:database).filled(Types::SanitizedString)
        required(:collection_tag).value(Types::SanitizedString)
        required(:output_format).value(array[Types::SanitizedString])
        required(:file_source_format).value(array[Types::SanitizedString])
      end

      # rubocop:disable Metrics/BlockLength
      json do
        required(:generated_files_dir).filled(:string)
        optional(:force_refresh_datastore).filled(Types::Bool)
        optional(:force_refresh).filled(Types::Bool)
        optional(:actions).value(Types::Array.of(Types::String))
        optional(:override_site).value(Types::String)

        optional(:stash_app).hash do
          optional(:url).value(Types::SanitizedString)
          optional(:api_token).maybe(Types::SanitizedString)
        end

        required(:global).hash do
          optional(:female_actors_prefix).filled(Types::SanitizedString)
          optional(:male_actors_prefix).filled(Types::SanitizedString)
          optional(:actors_prefix).filled(Types::SanitizedString)
          optional(:title_prefix).filled(Types::SanitizedString)
          optional(:id_prefix).filled(Types::SanitizedString)
          optional(:output_format).value(array[Types::SanitizedString])
        end

        required(:site).hash do
          optional(:adult_time).hash(SITE_CONFIG)
          optional(:arch_angel).hash(SITE_CONFIG)
          optional(:babes).hash(SITE_CONFIG)
          optional(:blacked).hash(SITE_CONFIG)
          optional(:blacked_raw).hash(SITE_CONFIG)
          optional(:brazzers).hash(SITE_CONFIG)
          optional(:deeper).hash(SITE_CONFIG)
          optional(:digital_playground).hash(SITE_CONFIG)
          optional(:elegant_angel).hash(SITE_CONFIG)
          optional(:evil_angel).hash(SITE_CONFIG)
          optional(:goodporn).hash(SITE_CONFIG)
          optional(:jules_jordan).hash(SITE_CONFIG)
          optional(:manuel_ferrara).hash(SITE_CONFIG)
          optional(:mofos).hash(SITE_CONFIG)
          optional(:naughty_america).hash(NAUGHTY_AMERICA_CONFIG)
          optional(:nf_busty).hash(NF_BUSTY_CONFIG)
          optional(:reality_kings).hash(SITE_CONFIG)
          optional(:stash).hash(STASH_CONFIG)
          optional(:tushy).hash(SITE_CONFIG)
          optional(:tushy_raw).hash(SITE_CONFIG)
          optional(:twistys).hash(SITE_CONFIG)
          optional(:vixen).hash(SITE_CONFIG)
          optional(:whale_media).hash(SITE_CONFIG)
          optional(:wicked).hash(SITE_CONFIG)
          optional(:x_empire).hash(SITE_CONFIG)
          optional(:zero_tolerance).hash(SITE_CONFIG)
        end

        required(:file_pre_process).array(:hash) do
          required(:regex).filled(:string)
          required(:with).value(:string)
        end
      end
      # rubocop:enable Metrics/BlockLength

      rule(:generated_files_dir) do
        key.failure("does not exist or is not readable") unless valid_dir?(value)
      end

      rule("global.female_actors_prefix") { key.failure(INVALID_PREFIX_MSG) unless prefix_valid?(value) }
      rule("global.male_actors_prefix") { key.failure(INVALID_PREFIX_MSG) unless prefix_valid?(value) }
      rule("global.actors_prefix") { key.failure(INVALID_PREFIX_MSG) unless prefix_valid?(value) }
      rule("global.title_prefix") { key.failure(INVALID_PREFIX_MSG) unless prefix_valid?(value) }
      rule("global.id_prefix") { key.failure(INVALID_PREFIX_MSG) unless prefix_valid?(value) }

      # Validate output format
      rule("global.output_format") { validate_format!(key, value) }
      rule("site.adult_time.output_format") { validate_format!(key, value) }
      rule("site.arch_angel.output_format") { validate_format!(key, value) }
      rule("site.babes.output_format") { validate_format!(key, value) }
      rule("site.blacked.output_format") { validate_format!(key, value) }
      rule("site.blacked_raw.output_format") { validate_format!(key, value) }
      rule("site.brazzers.output_format") { validate_format!(key, value) }
      rule("site.deeper.output_format") { validate_format!(key, value) }
      rule("site.digital_playground.output_format") { validate_format!(key, value) }
      rule("site.elegant_angel.output_format") { validate_format!(key, value) }
      rule("site.evil_angel.output_format") { validate_format!(key, value) }
      rule("site.jules_jordan.output_format") { validate_format!(key, value) }
      rule("site.manuel_ferrara.output_format") { validate_format!(key, value) }
      rule("site.mofos.output_format") { validate_format!(key, value) }
      rule("site.naughty_america.output_format") { validate_format!(key, value) }
      rule("site.nf_busty.output_format") { validate_format!(key, value) }
      rule("site.reality_kings.output_format") { validate_format!(key, value) }
      rule("site.stash.output_format") { validate_format!(key, value) }
      rule("site.tushy.output_format") { validate_format!(key, value) }
      rule("site.tushy_raw.output_format") { validate_format!(key, value) }
      rule("site.twistys.output_format") { validate_format!(key, value) }
      rule("site.vixen.output_format") { validate_format!(key, value) }
      rule("site.whale_media.output_format") { validate_format!(key, value) }
      rule("site.wicked.output_format") { validate_format!(key, value) }
      rule("site.x_empire.output_format") { validate_format!(key, value) }
      rule("site.zero_tolerance.output_format") { validate_format!(key, value) }

      rule("site.adult_time.file_source_format") { validate_source_format!(key, value) }
      rule("site.arch_angel.file_source_format") { validate_source_format!(key, value) }
      rule("site.babes.file_source_format") { validate_source_format!(key, value) }
      rule("site.blacked.file_source_format") { validate_source_format!(key, value) }
      rule("site.blacked_raw.file_source_format") { validate_source_format!(key, value) }
      rule("site.brazzers.file_source_format") { validate_source_format!(key, value) }
      rule("site.deeper.file_source_format") { validate_source_format!(key, value) }
      rule("site.digital_playground.file_source_format") { validate_source_format!(key, value) }
      rule("site.elegant_angel.file_source_format") { validate_source_format!(key, value) }
      rule("site.evil_angel.file_source_format") { validate_source_format!(key, value) }
      rule("site.mofos.file_source_format") { validate_source_format!(key, value) }
      rule("site.jules_jordan.file_source_format") { validate_source_format!(key, value) }
      rule("site.manuel_ferrara.file_source_format") { validate_source_format!(key, value) }
      rule("site.naughty_america.file_source_format") { validate_source_format!(key, value) }
      rule("site.nf_busty.file_source_format") { validate_source_format!(key, value) }
      rule("site.reality_kings.file_source_format") { validate_source_format!(key, value) }
      rule("site.stash.file_source_format") { validate_source_format!(key, value) }
      rule("site.tushy.file_source_format") { validate_source_format!(key, value) }
      rule("site.tushy_raw.file_source_format") { validate_source_format!(key, value) }
      rule("site.twistys.file_source_format") { validate_source_format!(key, value) }
      rule("site.vixen.file_source_format") { validate_source_format!(key, value) }
      rule("site.whale_media.file_source_format") { validate_source_format!(key, value) }
      rule("site.wicked.file_source_format") { validate_source_format!(key, value) }
      rule("site.x_empire.file_source_format") { validate_source_format!(key, value) }
      rule("site.zero_tolerance.file_source_format") { validate_source_format!(key, value) }
      rule("site.adult_time.file_source_format",
           "site.arch_angel.file_source_format",
           "site.babes.file_source_format",
           "site.blacked.file_source_format",
           "site.blacked_raw.file_source_format",
           "site.brazzers.file_source_format",
           "site.deeper.file_source_format",
           "site.digital_playground.file_source_format",
           "site.elegant_angel.file_source_format",
           "site.evil_angel.file_source_format",
           "site.jules_jordan.file_source_format",
           "site.manuel_ferrara.file_source_format",
           "site.mofos.file_source_format",
           "site.naughty_america.file_source_format",
           "site.nf_busty.file_source_format",
           "site.reality_kings.file_source_format",
           "site.stash.file_source_format",
           "site.tushy.file_source_format",
           "site.tushy_raw.file_source_format",
           "site.twistys.file_source_format",
           "site.vixen.file_source_format",
           "site.whale_media.file_source_format",
           "site.wicked.file_source_format",
           "site.x_empire.file_source_format",
           "site.zero_tolerance.file_source_format") { validate_uniqueness!(key(:duplicate_source_file_format), values) }

      rule("site.stash.username", "site.stash.password") do
        next unless key?("site.stash.username") && key?("site.stash.password")

        presence_arr = [values["site.stash.username"], values["site.stash.password"]].map(&:to_s).map(&:presence)
        if presence_arr.all?(NIL)
          true
        elsif presence_arr.none?(NIL)
          true
        else
          key(:stash_credentials).failure("provide both username and password if you want to use login credentials")
        end
      end

      rule("file_pre_process") { validate_pre_processor_rules(key, value) }

      private

      INVALID_PREFIX_MSG = "should only contain A-Z a-z 0-9 [ ] _ -"
      INVALID_PREFIX_CHARACTERS = /[^\w\[\]-]/.freeze

      def prefix_valid?(prefix)
        !INVALID_PREFIX_CHARACTERS.match?(prefix)
      end

      def validate_format!(key, value)
        value.each { |format| filename_generator.validate_format!(format) }
        true
      rescue InvalidFormatError => e
        key.failure(e.message)
      end

      def validate_source_format!(key, value)
        value.each { |format| filename_generator.validate_input_format!(format) }
        true
      rescue InvalidFormatError => e
        key.failure(e.message)
      end

      def validate_uniqueness!(key, values)
        source_file_formats = []
        values[:site].each_value { |x| source_file_formats.push(*x[:file_source_format]) }
        duplicates = find_duplicates(source_file_formats)
        return true if duplicates.empty?

        key.failure(duplicates.map { |x| "'#{x}'" }.join(", "))
      end

      def find_duplicates(ary)
        frequency = {}
        ary.map do |x|
          frequency[x] = if frequency.key?(x)
                           frequency[x] + 1
                         else
                           1
                         end
        end
        resp = []
        frequency.each_pair { |key, value| resp << key if value > 1 }
        resp
      end

      def validate_pre_processor_rules(key, values)
        messages = []
        values.each do |rule|
          Regexp.new(rule[:regex])

          message << "regex rule cannot be empty" if rule[:regex].blank?
        rescue RegexpError => e
          messages << "Rule #{rule[:regex]} failed to parse due to error #{e.message}"
        end

        key.failure(messages.join(",")) unless messages.empty?
      end
    end
  end
end
