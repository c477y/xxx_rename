# frozen_string_literal: true

module XxxRename
  module SiteClients
    class DigitalPlayground < MgPremium
      site_client_name :digital_playground

      def initialize
        super(site_url: "https://www.digitalplayground.com")
      end
    end
  end
end
