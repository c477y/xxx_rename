# frozen_string_literal: true

require "xxx_rename/site_clients/mg_premium"

module XxxRename
  module SiteClients
    class Babes < MGPremium
      site_client_name :babes

      def initialize(config)
        super(config, site_url: "https://www.babes.com")
      end
    end
  end
end
