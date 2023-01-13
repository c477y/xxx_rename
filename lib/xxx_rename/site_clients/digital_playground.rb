# frozen_string_literal: true

require "xxx_rename/site_clients/mg_premium"

module XxxRename
  module SiteClients
    class DigitalPlayground < MGPremium
      site_client_name :digital_playground

      def initialize(config)
        super(config, site_url: "https://www.digitalplayground.com")
      end
    end
  end
end
