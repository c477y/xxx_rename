# frozen_string_literal: true

require "xxx_rename/site_clients/vixen_media"

module XxxRename
  module SiteClients
    class TushyRaw < VixenMedia
      base_uri "https://www.tushyraw.com"
      site_client_name :tushy_raw
    end
  end
end
