# frozen_string_literal: true

require "xxx_rename/site_clients/manuel_ferrara_media"
require "xxx_rename/site_clients/query_generator/base"

module XxxRename
  module SiteClients
    class ManuelFerrara < ManuelFerraraMedia
      base_uri "https://manuelferrara.com/"

      site_client_name :manuel_ferrara

      COLLECTION = "Manuel Ferrara"

      SCENES_ENDPOINT_TRIAL = "/trial/categories/movies_$page$_d.html"

      def search(filename)
        refresh_datastore(1) if datastore_refresh_required?
        match = SiteClients::QueryGenerator::Base.generic_generate(filename, source_format)
        lookup_in_datastore!(match)
      end
    end
  end
end
