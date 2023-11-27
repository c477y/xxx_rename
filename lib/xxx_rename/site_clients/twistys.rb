# frozen_string_literal: true

module XxxRename
  module SiteClients
    class Twistys < MgPremium
      site_client_name :twistys

      def initialize
        super(site_url: "https://www.twistys.com")
      end
    end
  end
end
