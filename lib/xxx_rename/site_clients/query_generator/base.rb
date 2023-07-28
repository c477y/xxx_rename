# frozen_string_literal: true

require "xxx_rename/utils"

module XxxRename
  module SiteClients
    module QueryGenerator
      class Base
        SearchParameters = Struct.new(:title, :id, :female_actors, :movie, :collection,
                                      :male_actors, :actors, :collection_tag, :date_released,
                                      :processed, :index, keyword_init: true)

        attr_reader :filename, :processed_file_patterns, :source_pattern

        def self.generate(_filename, *_patterns)
          raise "Not Implemented"
        end

        def self.generic_generate(filename, patterns)
          new(filename, [], patterns).parse
        end

        # @param [String] filename
        # @param [Array[String]] source_pattern
        # @param [Array[String]] processed_file_patterns
        def initialize(filename, source_pattern, processed_file_patterns)
          @filename = filename
          @source_pattern = source_pattern
          @processed_file_patterns = processed_file_patterns
        end

        # Attempt to generate search parameters using three approaches
        # 1. Use the source format if passed (handled by base)
        # 2. Assume the file had already been processed and use `ProcessedFile` (handled by base using ProcessedFile.parse)
        # 3. Use any formats given by the query generator
        # 4. Treat the file as downloaded from official source (handled by each site client query generator)
        # @return [Nil, XxxRename::Data::SceneData]
        def parse
          parse_file_with_source_pattern || # Use the user provided source format
            parse_file || # Assume file format matches default format of CLI
            parse_file_with_patterns # Use any formats given by the query generator
        end

        private

        def parse_file
          parse_file!
        rescue XxxRename::Errors::ParsingError, Dry::Struct::Error => e
          XxxRename.logger.debug e
          nil
        end

        def parse_file!
          ProcessedFile.parse(filename)
        end

        def parse_file_with_source_pattern
          parse_file_with_source_pattern!
        rescue XxxRename::Errors::ParsingError, Dry::Struct::Error => e
          XxxRename.logger.debug e
          nil
        end

        def parse_file_with_source_pattern!
          source_pattern.map do |sp|
            resp = ProcessedFile.strpfile(filename, sp)
            return resp unless resp.nil?
          end
          nil
        end

        def parse_file_with_patterns
          processed_file_patterns.compact
                                 .map { |x| parse_file_with_pattern(x) }
                                 .compact
                                 .first
        end

        def parse_file_with_pattern!(pattern)
          ProcessedFile.strpfile(filename, pattern)
        end

        def parse_file_with_pattern(pattern)
          parse_file_with_pattern!(pattern)
        rescue XxxRename::Errors::ParsingError, Dry::Struct::Error => e
          XxxRename.logger.debug e
          nil
        end
      end
    end
  end
end
