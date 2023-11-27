# frozen_string_literal: true

module XxxRename
  module Data
    class MatchResponse < Base
      attribute :filename, Types::String
      attribute :parsed_scene_data, Data::ParsedSceneData
      attribute :site_client, Types.Instance(XxxRename::SiteClients::Base)
      attribute :unprocessed, Types::Bool.default(false)

      def unprocessed?
        unprocessed
      end
    end
  end
end
