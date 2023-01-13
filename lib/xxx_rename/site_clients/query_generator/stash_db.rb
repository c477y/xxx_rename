# frozen_string_literal: true

require "xxx_rename/site_clients/query_generator/base"

module XxxRename
  module SiteClients
    module QueryGenerator
      class StashDb < Base
        extend Utils

        def self.generate(filename, source_format)
          return unless (data = new(filename, source_format, []).parse)

          SearchParameters.new(**data.to_h.slice(:title, :id, :female_actors, :movie, :collection,
                                                 :male_actors, :actors, :collection_tag, :date_released,
                                                 :processed, :index))
        end
      end
    end
  end
end
