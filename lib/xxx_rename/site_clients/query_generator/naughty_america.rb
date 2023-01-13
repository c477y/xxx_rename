# frozen_string_literal: true

require "xxx_rename/site_clients/query_generator/base"

module XxxRename
  module SiteClients
    module QueryGenerator
      class NaughtyAmerica < Base
        extend Utils

        def self.generate(filename, source_format)
          if (data = new(filename, source_format, []).parse)
            SearchParameters.new(**data.to_h)
          else
            # Make sure to do this match to prevent unnecessary calls to API
            return unless filename.match? Constants::NAUGHTY_AMERICA_ORIGINAL_FILE_REGEX

            filename.match(Constants::NAUGHTY_AMERICA_ORIGINAL_FILE_REGEX)[:compressed_scene]
          end
        end
      end
    end
  end
end
