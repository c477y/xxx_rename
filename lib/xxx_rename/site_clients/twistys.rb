# frozen_string_literal: true

require "xxx_rename/site_clients/mg_premium"

module XxxRename
  module SiteClients
    class Twistys < MGPremium
      site_client_name :twistys

      def initialize(config)
        super(config, site_url: "https://www.twistys.com")
      end
    end
  end
end
