# frozen_string_literal: true

require "xxx_rename/site_clients/query_generator/base"

module XxxRename
  module SiteClients
    module QueryGenerator
      class MgPremium < Base
        extend Utils

        def self.generate(filename, source_format)
          if (data = new(filename, source_format, []).parse)
            SearchParameters.new(title: data.title)
          else
            # Make sure to do this match to prevent unnecessary calls to API
            return unless filename.match? Constants::MG_PREMIUM_ORIGINAL_FILE_FORMAT

            basename = File.basename(filename, ".*")
            scene_title = basename.split("_").first&.split("-")
            SearchParameters.new(title: adjust_apostrophe(scene_title))
          end
        end
      end
    end
  end
end
