# frozen_string_literal: true

module XxxRename
  module SiteClients
    class Brazzers < MgPremium
      site_client_name :brazzers

      def initialize
        super(site_url: "https://www.brazzers.com")
      end
    end
  end
end
