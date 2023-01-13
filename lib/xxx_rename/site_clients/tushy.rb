# frozen_string_literal: true

require "xxx_rename/site_clients/vixen_media"

module XxxRename
  module SiteClients
    class Tushy < VixenMedia
      base_uri "https://www.tushy.com"
      site_client_name :tushy
    end
  end
end
