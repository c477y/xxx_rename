# frozen_string_literal: true

require "xxx_rename/site_clients/jules_jordan_media"
require "xxx_rename/site_clients/query_generator/base"

module XxxRename
  module SiteClients
    class JulesJordan < JulesJordanMedia
      base_uri "https://www.julesjordan.com"

      site_client_name :jules_jordan

      COLLECTION = "Jules Jordan"

      def search(filename)
        refresh_datastore(1) if datastore_refresh_required?
        match = SiteClients::QueryGenerator::Base.generic_generate(filename, source_format)
        lookup_in_datastore!(match)
      end
    end
  end
end
