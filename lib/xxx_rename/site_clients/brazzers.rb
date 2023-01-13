# frozen_string_literal: true

require "xxx_rename/site_clients/mg_premium"

module XxxRename
  module SiteClients
    class Brazzers < MGPremium
      site_client_name :brazzers

      def initialize(config)
        super(config, site_url: "https://www.brazzers.com")
      end
    end
  end
end
