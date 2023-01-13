# frozen_string_literal: true

require "xxx_rename/site_clients/query_generator/base"

module XxxRename
  module SiteClients
    module QueryGenerator
      class Whale < Base
        extend Utils

        # Generated using default format
        PATTERN_1 = "%female_actors [T] %title [%collection_tag_2] %collection [ID] %id"
        PATTERN_2 = "%female_actors [T] %title [%collection_tag_2] %collection"

        def self.generate(filename, source_format)
          query = new(filename, source_format, [PATTERN_1, PATTERN_2])
          resp = query.parse
          if resp
            SearchParameters.new(
              collection: resp.collection.normalize.to_sym,
              title: resp.title&.downcase&.gsub(/\s/, "-"),
              id: resp.id.to_s
            )
          else
            match = filename.match(Constants::WHALE_ORIGINAL_FILE_PATTERN)
            return if match.nil?

            SearchParameters.new(
              collection: match[:site]&.to_sym,
              title: match[:title],
              # At this time, we don't know what the id tag of the scene is
              id: ""
            )
          end
        end
      end
    end
  end
end
