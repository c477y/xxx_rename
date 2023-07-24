# frozen_string_literal: true
# frozen_string_literal: true

require "xxx_rename/site_clients/vixen_media"

module XxxRename
  module SiteClients
    class Deeper < VixenMedia
      base_uri "https://www.deeper.com"
      site_client_name :deeper
    end
  end
end
