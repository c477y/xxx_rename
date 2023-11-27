# frozen_string_literal: true

module XxxRename
  module SiteClients
    class Babes < MgPremium
      site_client_name :babes

      def initialize
        super(site_url: "https://www.babes.com")
      end
    end
  end
end
