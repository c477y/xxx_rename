# frozen_string_literal: true

require "xxx_rename/site_clients/vixen_media"

module XxxRename
  module SiteClients
    class Vixen < VixenMedia
      base_uri "https://www.vixen.com"
      site_client_name :vixen
    end
  end
end
