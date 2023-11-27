# frozen_string_literal: true

module XxxRename
  module SiteClients
    class RealityKings < MgPremium
      site_client_name :reality_kings
      def initialize
        super(site_url: "https://www.realitykings.com")
      end
    end
  end
end
