# frozen_string_literal: true

require "httparty"
require "nokogiri"

module XxxRename
  module SiteClients
    module AlgoliaCommon
      CLIENT_KEY_JS_REGEX_1 = /var\sclient\s=\salgoliasearch\('(?<application_id>\w+)',\s'(?<api_key>[\w=]+)'\);/x.freeze
      CLIENT_KEY_JS_REGEX_2 = /
      window\.env\s*=\s*{
        "api":{
          "algolia":{
            "applicationID":"(?<application_id>\w+)",
            "apiKey":"(?<api_key>[\w=]+)"
          }
        }/x.freeze

      ALGOLIA_RATE_LIMIT_MESSAGE = "Too many requests"
      ALGOLIA_RATE_LIMIT_STATUS = 429
      ALGOLIA_EXPIRY_MESSAGE = "\"validUntil\" parameter expired (less than current date)"
      ALGOLIA_EXPIRY_STATUS = 400

      AlgoliaParams = Struct.new(:application_id, :api_key, keyword_init: true)

      def algolia_params!(site)
        doc = Nokogiri::HTML HTTParty.get(site, headers: Constants::DEFAULT_HEADERS).parsed_response
        js = doc.search("script").text
        match = js.match(CLIENT_KEY_JS_REGEX_1) || js.match(CLIENT_KEY_JS_REGEX_2)
        raise "Unable to fetch algolia credentials" if match.nil?

        AlgoliaParams.new(application_id: match[:application_id], api_key: match[:api_key])
      end

      def actors_contained?(actors_from_file, actors_from_response)
        #  All actors in actors_from_file should be contained in actors_from_response
        get_actor = ->(hsh) { hsh[:name] }
        actors_from_file_set = actors_from_file.map(&:normalize).to_set
        actors_from_response_set = actors_from_response.map(&get_actor).map(&:normalize).to_set
        actors_from_file_set.subset? actors_from_response_set
      end

      def date_released(resp)
        Time.strptime(resp[:release_date].strip, "%Y-%m-%d")
      end
    end
  end
end
