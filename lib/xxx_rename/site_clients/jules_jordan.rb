# frozen_string_literal: true

module XxxRename
  module SiteClients
    class JulesJordan < JulesJordanMedia
      base_uri "https://www.julesjordan.com"

      site_client_name :jules_jordan

      COLLECTION = "Jules Jordan"

      # @param [String] _filename
      # @param [Data::ParsedSceneData] parsed_scene_data
      def search(_filename, parsed_scene_data:, **opts)
        refresh_datastore(1) if datastore_refresh_required?
        lookup_in_datastore!(parsed_scene_data)
      end
    end
  end
end
