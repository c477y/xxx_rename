# frozen_string_literal: true

require "singleton"

module XxxRename
  class ActorsHelper
    include Singleton

    def matcher(matcher = nil)
      raise Errors::FatalError, "#{self.class.name} initialised without matcher" if @matcher.nil? && matcher.nil?

      @matcher ||= matcher
    end

    def female_actors
      @female_actors ||= {}
    end

    def male_actors
      @male_actors ||= {}
    end

    def append_female(actor_hash)
      female_actors[actor_hash["compressed_name"]] = actor_hash["name"] if female_actors[actor_hash["compressed_name"]].nil?
    end

    def append_male(actor_hash)
      male_actors[actor_hash["compressed_name"]] = actor_hash["name"] if male_actors[actor_hash["compressed_name"]].nil?
    end

    def male?(actor)
      processed!(actor)
      male_actors.key? actor.normalize
    rescue Errors::UnprocessedEntity
      false
    end

    def female?(actor)
      processed!(actor)
      female_actors.key? actor.normalize
    rescue Errors::UnprocessedEntity
      false
    end

    def processed?(actor)
      processed!(actor)
    rescue Errors::UnprocessedEntity
      false
    end

    def processed!(actor)
      return true if female_actors.key?(actor.normalize) || male_actors.key?(actor.normalize)

      raise Errors::UnprocessedEntity, actor
    end

    def auto_fetch!(actor)
      details = fetch_actor_details.details(actor)

      raise Errors::UnprocessedEntity, actor if details.nil?

      details["gender"].downcase == "female" ? append_female(details) : append_male(details)
      nil
    end

    def auto_fetch(actor)
      auto_fetch!(actor)
    rescue Errors::UnprocessedEntity => e
      XxxRename.logger.warn "Unable to fetch details for #{e.message}"
      nil
    end

    private

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
        details.tap do |h|
          h["compressed_name"] = details["name"].normalize
          h["gender"]          = details["gender"].normalize
        end
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
      ].compact
    end
  end
end
