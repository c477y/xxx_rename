# frozen_string_literal: true

require "xxx_rename/site_clients/query_generator/base"

module XxxRename
  module SiteClients
    module QueryGenerator
      class Goodporn < Base
        extend Utils

        def self.generate(filename, source_format)
          if (data = new(filename, source_format, []).parse)
            return if data.date_released.nil?

            "#{data.collection} #{data.title} #{data.date_released.strftime("%m %d %Y")}"
              .downcase
              .gsub(/[^\w\s]/, "")
              .gsub(/\s+/, "-")
          else
            # Make sure to do this match to prevent unnecessary calls to API
            return unless filename.match? Constants::GOODPORN_ORIGINAL_FILE_FORMAT

            File.basename(filename, ".*").split("_")[0]
          end
        end
      end
    end
  end
end
