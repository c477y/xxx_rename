# frozen_string_literal: true

module XxxRename
  class ActorsHelper
    # @param [XxxRename::Data::ActorsDatastoreQuery] datastore
    # @param [XxxRename::SiteClientMatcher] matcher
    def initialize(datastore, matcher)
      @actors_datastore = datastore
      @matcher = matcher
    end

    def male?(actor)
      actors_datastore.male?(actor)
    end

    def female?(actor)
      actors_datastore.female?(actor)
    end

    # @param [String] actor
    def auto_fetch!(actor)
      details = fetch_actor_details.details(actor)

      raise Errors::UnprocessedEntity, actor if details.nil?

      actors_datastore.create!(details["name"], "female") if details["gender"] == "female"
      actors_datastore.create!(details["name"], "male")   if details["gender"] == "male"
      nil
    end

    def auto_fetch(actor)
      auto_fetch!(actor)
    rescue Errors::UnprocessedEntity => e
      XxxRename.logger.warn "Unable to fetch details for #{e.message}"
      nil
    end

    private

    attr_reader :actors_datastore, :matcher

    def fetch_actor_details
      @fetch_actor_details ||= FetchActorDetails.new(matcher)
    end
  end

  class FetchActorDetails
    # @param [XxxRename::SiteClientMatcher] matcher
    def initialize(matcher)
      @matcher = matcher
    end

    # @param [String] actor Search string for actor
    # @return [nil, Hash] Hash of details or nil if not found
    def details(actor)
      clients.each do |client|
        details = client.actor_details(actor)
        next if details.nil?

        XxxRename.logger.debug "#{client.class.name.split("::").last} matched actor #{actor} as #{details["gender"]}"

        details["gender"] = details["gender"].normalize
        return details
      end
      nil
    end

    private

    attr_reader :matcher

    def clients
      [
        matcher.initialise_site_client(:stash),
        matcher.initialise_site_client(:brazzers),
        matcher.initialise_site_client(:wicked),
        matcher.initialise_site_client(:reality_kings),
        matcher.initialise_site_client(:evil_angel)
      ].compact # remove any disabled site clients
    end
  end
end
