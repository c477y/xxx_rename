# frozen_string_literal: true

require "xxx_rename/site_clients/mg_premium"

module XxxRename
  module SiteClients
    class RealityKings < MGPremium
      site_client_name :reality_kings
      def initialize(config)
        super(config, site_url: "https://www.realitykings.com")
      end
    end
  end
end
