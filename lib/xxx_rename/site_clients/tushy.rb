# frozen_string_literal: true

module XxxRename
  module SiteClients
    class Tushy < VixenMedia
      base_uri "https://www.tushy.com"
      site_client_name :tushy

      def foo
        self.class.get("/graphql")
      end
    end
  end
end
