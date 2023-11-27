# frozen_string_literal: true

module XxxRename
  module SiteClients
    class ManuelFerrara < ManuelFerraraMedia
      base_uri "https://manuelferrara.com/"

      site_client_name :manuel_ferrara

      COLLECTION = "Manuel Ferrara"

      SCENES_ENDPOINT_TRIAL = "/trial/categories/movies_$page$_d.html"

      # @param [String] _filename
      # @param [Data::ParsedSceneData] parsed_scene_data
      def search(_filename, parsed_scene_data:, **opts)
        refresh_datastore(1) if datastore_refresh_required?
        lookup_in_datastore!(parsed_scene_data)
      end
    end
  end
end
