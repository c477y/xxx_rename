# frozen_string_literal: true

require "xxx_rename/site_clients/query_generator/base"

module XxxRename
  module SiteClients
    module QueryGenerator
      class EvilAngel < Base
        extend Utils

        def self.generate(filename, source_format)
          if (data = new(filename, source_format, []).parse)
            SearchParameters.new(
              title: data.title,
              id: data.id,
              actors: data.actors,
              processed: true
            )
          else
            # Make sure to do this match to prevent unnecessary calls to API
            return unless filename.match?(Constants::EVIL_ANGEL_ORIGINAL_FILE_PATTERN)

            match = filename.match(Constants::EVIL_ANGEL_ORIGINAL_FILE_PATTERN)

            SearchParameters.new(
              actors: match[:actors]&.split("_"),
              title: match[:title].titleize_custom,
              index: match[:index],
              processed: false
            )
          end
        end
      end
    end
  end
end
