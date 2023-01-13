# frozen_string_literal: true

require "xxx_rename/site_clients/mg_premium"

module XxxRename
  module SiteClients
    class Mofos < MGPremium
      site_client_name :mofos

      def initialize(config)
        super(config, site_url: "https://www.mofos.com")
      end
    end
  end
end
