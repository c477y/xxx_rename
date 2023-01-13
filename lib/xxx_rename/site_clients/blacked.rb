# frozen_string_literal: true

require "xxx_rename/site_clients/vixen_media"

module XxxRename
  module SiteClients
    class Blacked < VixenMedia
      base_uri "https://www.blacked.com"
      site_client_name :blacked
    end
  end
end
