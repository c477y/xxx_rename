# frozen_string_literal: true

module XxxRename
  class FilenameGenerationError < StandardError
    attr_reader :extra_tokens

    def initialize(extra_tokens)
      @extra_tokens = extra_tokens
      super(message)
    end

    def message
      "Format contains token(s) #{@extra_tokens.join(", ")}, but site client returned no values for these arguments."
    end
  end

  class InvalidFormatError < StandardError
    def initialize(extra_tokens: [], contains_extension: nil)
      @extra_tokens = extra_tokens
      @contains_extension = contains_extension
      super(make_message)
    end

    def make_message
      if @extra_tokens.length.positive?
        "invalid token(s) #{@extra_tokens.join(", ")}"
      elsif @contains_extension
        "format should not contain extension but found #{@contains_extension}"
      else
        raise Errors::FatalError, "#{self.class.name} expects extra_tokens or contains_extension but received neither"
      end
    end
  end

  class FilenameGenerator
    VALID_TOKENS = %w[%female_actors %male_actors %actors %collection %collection_tag %title %id %yyyy_mm_dd %dd %mm %yyyy].freeze
    VALID_PREFIX_TOKENS = %w[%female_actors_prefix %male_actors_prefix %actors_prefix %title_prefix %id_prefix].freeze

    VALID_INPUT_TOKENS = %w[%title %collection %collection_op %collection_tag_1 %collection_tag_2 %collection_tag_3
                            %female_actors %male_actors %male_actors_op %actors
                            %id %id_op
                            %ignore_1_word %ignore_2_words %ignore_2_words %ignore_3_words %ignore_4_words
                            %ignore_5_words %ignore_6_words %ignore_7_words %ignore_all
                            %yyyy_mm_dd %dd %mm %yyyy %yy].freeze

    class << self
      #
      # Helper method for ConfigContract
      # Validates the global.output_format and
      # site.{site}.output_format attributes
      #
      # @param [String] format
      # @return [Boolean]
      # @raise [InvalidFormatError] if string contains invalid tokens
      def validate_format!(format)
        tokens_in_format = format.scan(/%\w+/)
        invalid_tokens = tokens_in_format - VALID_TOKENS - VALID_PREFIX_TOKENS
        return true if invalid_tokens.empty?

        raise InvalidFormatError.new(extra_tokens: invalid_tokens)
      end

      #
      # Helper method for ConfigContract
      # Validates the site.{site}.file_source_format attribute
      #
      # @param [String] format
      # @return [Boolean]
      # @raise [InvalidFormatError] if string contains invalid tokens
      def validate_input_format!(format)
        tokens_in_format = format.scan(/%\w+/)
        invalid_tokens = tokens_in_format - VALID_INPUT_TOKENS - VALID_PREFIX_TOKENS
        return true if invalid_tokens.empty?

        raise InvalidFormatError.new(extra_tokens: invalid_tokens)
      end

      def generate(scene_data, format, ext_name, prefix_hash)
        new.generate_filename(scene_data, format, ext_name, prefix_hash)
      end

      def generate_with_multi_formats!(scene_data, ext_name, prefix_hash, *formats)
        extra_tokens = []
        formats.each do |format|
          resp = new.generate_filename(scene_data, format, ext_name, prefix_hash)
          return resp
        rescue FilenameGenerationError => e
          extra_tokens.push(*e.extra_tokens)
          nil
        end
        raise FilenameGenerationError, extra_tokens.uniq
      end
    end

    # @param [XxxRename::Data::SceneData] scene_data
    # @param [String] format
    # @param [String] ext_name
    # @param [Hash] prefix_hash
    def generate_filename(scene_data, format, ext_name, prefix_hash)
      self.class.validate_format!(format) && validate_extension!(format, ext_name)

      all_tokens_in_format = format.scan(/%\w+/)
      tokens_in_format = all_tokens_in_format.reject { |x| x.end_with?("_prefix") }

      format = sub_tokens(scene_data, tokens_in_format, format)
      format = sub_prefix_tokens(scene_data, all_tokens_in_format, format, prefix_hash)

      validate_after_replacement!(format)

      "#{format.strip.remove_special_characters}#{ext_name}"
    end

    private

    def sub_tokens(scene_data, tokens, format)
      long_name_tokens = %w[%female_actors %male_actors %actors]

      tokens.each do |token|
        fn = token[1..].to_sym
        value = scene_data.send(fn)
        next if value.nil? || !value.to_s.presence

        value = "[#{value}]" if fn == :collection_tag && value !~ /\[\w+\]/
        next if long_name_tokens.include?(token)

        format = format.gsub(/#{token}\b/, value.to_s)
      end

      format = safe_append_list(format, "%actors", scene_data.actors)
      format = safe_append_list(format, "%female_actors", scene_data.female_actors)
      safe_append_list(format, "%male_actors", scene_data.male_actors)
    end

    def safe_append_list(str, token, arr, max_len = FileUtilities::MAX_FILENAME_LEN)
      return str if arr.empty? || !str.include?(token)

      formatted_str = str.gsub(/#{token}\b/, arr.join(", ").to_s)
      return formatted_str if formatted_str.length < max_len

      safe_append_list(str, token, arr[0...-1], max_len)
    end

    def sub_prefix_tokens(data, tokens, format, prefix_hash)
      tokens.each do |token|
        next unless token.end_with?("_prefix")

        value = data.send(token[1..].gsub("_prefix", "").to_sym)
        format = if value.nil? || value.empty?
                   format.gsub(/#{token}\b/, "")
                 else
                   format.gsub(/#{token}\b/, prefix_hash[token[1..].to_sym])
                 end
      end
      format
    end

    def validate_extension!(format, ext_name)
      raise InvalidFormatError.new(contains_extension: match[:ext]) if format.end_with?(ext_name)

      return unless (match = /.*(?<ext>\w{3,4})$/.match(format)) && Constants::VIDEO_EXTENSIONS.include?(match[:ext])

      raise InvalidFormatError.new(contains_extension: match[:ext])
    end

    # @param [String] file
    def validate_after_replacement!(file)
      tokens_in_format = file.scan(/%\w+/)
      return if tokens_in_format.empty?

      raise FilenameGenerationError, tokens_in_format
    end
  end
end
