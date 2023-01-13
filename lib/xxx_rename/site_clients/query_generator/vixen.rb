# frozen_string_literal: true

require "xxx_rename/site_clients/query_generator/base"

module XxxRename
  module SiteClients
    module QueryGenerator
      class Vixen < Base
        extend Utils

        PATTERN_1 = "%actors [T] %title [S] %collection [ID] %id"

        def self.generate(filename, source_format)
          if (data = new(filename, source_format, [PATTERN_1]).parse)
            SearchParameters.new(**data.to_h.slice(:title, :id, :female_actors, :collection, :male_actors, :actors))
          else
            re_match = filename.match(Constants::VIXEN_MEDIA_ORIGINAL_FILE_REGEX_1) ||
                       filename.match(Constants::VIXEN_MEDIA_ORIGINAL_FILE_REGEX_2)
            return if re_match.nil?

            SearchParameters.new(id: re_match[:id], collection: re_match[:collection])
          end
        end
      end
    end
  end
end
