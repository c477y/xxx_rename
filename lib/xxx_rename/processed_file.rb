# frozen_string_literal: true

module XxxRename
  # noinspection RubyClassVariableUsageInspection
  # rubocop:disable Style/ClassVars TODO: Find an alternative approach to not use class variables
  class ProcessedFile
    @@prefix_regex_maps = {}

    CHARS = "[\\w\\s\\-_,'\"\\.]+"
    OPTIONAL_CHARS = "[\\w\\s\\-_,'\"]*"
    IDENTIFIER = "(\\d+|[a-z\\-\\_]+)"
    OPTIONAL_IDENTIFIER = "(\\d*|[a-z\\-\\_]*)"

    # rubocop:disable Layout/HashAlignment
    TOKEN_REGEX_MAP = {
      # Scene Title
      "%title"                    => "(?<title>#{CHARS})",

      # Scene Collection
      "%collection"               => "(?<collection>#{CHARS})",
      "%collection_op"            => "(?<collection>#{OPTIONAL_CHARS}?)",
      "%collection_tag_1"         => "(?<collection_tag>\\w)",
      "%collection_tag_2"         => "(?<collection_tag>\\w{1,2})",
      "%collection_tag_3"         => "(?<collection_tag>\\w{1,3})",

      # Actors (Words separated by spaces, hyphen(-), underscore(_))
      # Multiple actors(female, male or actors) can be parsed with a single tag
      # Do not mix `actors` with any other tags
      "%female_actors"            => "(?<female_actors>#{CHARS})",
      "%male_actors"              => "(?<male_actors>#{CHARS})",
      "%male_actors_op"           => "(?<male_actors>#{OPTIONAL_CHARS})?",
      "%actors"                   => "(?<actors>#{CHARS})",

      # Scene ID
      "%id"                       => "(?<id>#{IDENTIFIER})",
      "%id_op"                    => "(?<id>#{OPTIONAL_IDENTIFIER})?",

      # Ignore n words (space separated)
      "%ignore_1_word"            => "(\\w\\s){1}",
      "%ignore_2_words"           => "(\\w\\s){2}",
      "%ignore_3_words"           => "(\\w\\s){3}",
      "%ignore_4_words"           => "(\\w\\s){4}",
      "%ignore_5_words"           => "(\\w\\s){5}",
      "%ignore_6_words"           => "(\\w\\s){6}",
      "%ignore_7_words"           => "(\\w\\s){7}",

      "%ignore_all"               => ".*",

      # Date
      "%yyyy_mm_dd"               => "(?<year>\\d{4})_(?<month>\\d{1,2})_(?<day>\\d{1,2})",
      "%yyyy/mm/dd"               => "(?<year>\\d{4})/(?<month>\\d{1,2})/(?<day>\\d{1,2})",
      "%yyyy-mm-dd"               => "(?<year>\\d{4})-(?<month>\\d{1,2})-(?<day>\\d{1,2})",
      "%dd"                       => "(?<day>\\d{1,2})",
      "%mm"                       => "(?<month>\\d{1,2})",
      "%yyyy"                     => "(?<year>\\d{4})",
      "%yy"                       => "(?<year>\\d{2})"
    }.freeze
    # rubocop:enable Layout/HashAlignment

    # @param [XxxRename::Data::Config::Global] hash
    def self.prefix_hash_set(hash)
      return unless @@prefix_regex_maps.empty?

      # rubocop:disable Layout/HashAlignment
      @@prefix_regex_maps = {
        "%female_actors_prefix"      => "(?<female_actors_prefix>#{Regexp.quote(hash[:female_actors_prefix])})",
        "%male_actors_prefix"        => "(?<male_actors_prefix>#{Regexp.quote(hash[:male_actors_prefix])})",
        "%actors_prefix"             => "(?<actors_prefix>#{Regexp.quote(hash[:actors_prefix])})",
        "%title_prefix"              => "(?<title_prefix>#{Regexp.quote(hash[:title_prefix])})",
        "%id_prefix"                 => "(?<id_prefix>#{Regexp.quote(hash[:id_prefix])})"
      }
      # rubocop:enable Layout/HashAlignment
    end

    def self.prefix_regex_maps
      @@prefix_regex_maps
    end

    attr_reader :file

    # @param [String] file File to match
    # @param [String] pattern A regular expression to match the file
    # @return [Data::ParsedSceneData]
    def self.strpfile(file, pattern)
      object = new(file)
      regex = object.make_regex!(pattern)

      resp = object.match_file(regex)
      raise Errors::ParsingError.new(file, regex) if resp.nil?

      resp
    end

    # @param [String] file Name of file
    def initialize(file)
      @file = file

      XxxRename.config.file_pre_process.each { |processor| @file = processor.replace(@file) }
    end

    # @param [String] pattern
    def make_regex!(pattern)
      token_regex = /%\w+\b/
      tokens = pattern.scan(token_regex)
      validate_tokens!(tokens)

      regex = Regexp.quote(pattern).to_s
      tokens.each do |m|
        regex = regex.gsub(m, TOKEN_REGEX_MAP[m]) if TOKEN_REGEX_MAP.key?(m)
        regex = regex.gsub(m, @@prefix_regex_maps[m]) if @@prefix_regex_maps.key?(m)
      end
      Regexp.new regex
    end

    # @param [Array[Regex]] regexes
    def match_file(*regexes)
      regexes.map { |regex| process_regex!(regex) }.compact.first
    end

    # noinspection RubyMismatchedReturnType
    # @return [Data::SceneData]
    def process_regex!(regex) # rubocop:disable Metrics/CyclomaticComplexity
      file_without_ext = File.basename(file, File.extname(file))
      match = file_without_ext.match(regex)
      return if match.nil?

      match_hash = match.named_captures.tap do |h|
        h["female_actors"]  = clean_actor_str(h["female_actors"])
        h["male_actors"]    = clean_actor_str(h["male_actors"])
        h["actors"]         =
          h["actors"].present? ? clean_actor_str(h["actors"]) : h["female_actors"] + h["male_actors"]
        h["collection"]     = h["collection"] if h["collection"].present?
        h["collection_tag"] = h["collection_tag"] if h["collection_tag"].present?
        h["title"]          = h["title"] if h["title"].present?
        h["id"]             = h["id"] if h["id"].present?
        h["date_released"]  = date_released(h["year"], h["month"], h["day"]) if date_released(h["year"], h["month"],
                                                                                              h["day"])
      end

      Data::ParsedSceneData.new(match_hash)
    end

    private

    # For a set of tokens to be valid, all of the tokens
    # should have a respective rule AKA 'value' in the combined
    # hash of TOKEN_REGEX_MAP and @@prefix_regex_maps
    # @param [Array[String]] tokens
    def validate_tokens!(tokens)
      combined_token_map = TOKEN_REGEX_MAP.merge(@@prefix_regex_maps)
      invalid_tokens = tokens.select { |x| combined_token_map[x].nil? }
      raise ArgumentError, "Invalid tokens #{invalid_tokens.join(", ")} in pattern." unless invalid_tokens.empty?
    end

    # @return [Nil, Time]
    def date_released(year, month, day)
      Time.new(year, month, day) if year && month && day
    rescue ArgumentError => e
      XxxRename.logger.warn "[TIME PARSE ERROR] input: year: #{year}, month: #{month}, day: #{day}, error: #{e.message}"
      nil
    end

    # @param [String] str A String extracted from the regex match
    # @return [Array[String]]
    def clean_actor_str(str)
      return [] unless str.presence

      str.split(",").map(&:strip).map(&:presence).sort.compact
    end
  end
end

# rubocop:enable Style/ClassVars
