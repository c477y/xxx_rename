# frozen_string_literal: true

module XxxRename
  module SiteClients
    class Mofos < MgPremium
      site_client_name :mofos

      def initialize
        super(site_url: "https://www.mofos.com")
      end
    end
  end
end
