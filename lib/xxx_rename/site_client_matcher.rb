# frozen_string_literal: true

require "set"

require "xxx_rename/site_clients/base"
require "xxx_rename/site_clients/errors"

module XxxRename
  class SiteClientMatcher
    MatchResponse = Struct.new(:parsed_info, :site_client, :unprocessed, keyword_init: true)

    # @param [XxxRename::Data::Config] config
    def initialize(config, override_site: nil)
      @config = config
      @override_site = override_site
    end

    # @param [String] file
    # @return [Array[MatchResponse]]
    def match(file)
      @match_response = []
      find_matches(file)
      @match_response
    end

    def fetch(key)
      site_clients.fetch(key.to_sym, nil)
    end

    #
    # Disable a site client permanently for the duration of the
    # program runtime. This is helpful when we are rate limited,
    # or fail auth for sites that require one, and protects
    # the app from calling the API unnecessarily. Once a site
    # is disabled, the matcher will never return the site client
    # even after a successful match
    #
    # @param [XxxRename::SiteClients::Base] client
    # @return [Set[String]]
    def disable_site(client)
      site_client_sym = client.class.site_client_name
      site_clients[site_client_sym] = nil
      disabled_sites.add(site_client_sym)
    end

    def site_disabled?(site)
      disabled_sites.member?(site)
    end

    #
    # Initialise a site client and store it in memory
    # Consecutive calls to this method with the same site
    # client name will not cause it to reinitialise the
    # site client. This can provide performance benefits
    # if the site client needs to do some work during
    # initialisation, e.g. login, fetch tokens, etc
    #
    # Usually, you won't need to call this method manually,
    # as the matcher will do it for you. But it can be used
    # by certain functions like ActorsHelper.
    #
    # @param [Symbol] site
    # @return [XxxRename::SiteClients::Base]
    def initialise_site_client(site)
      return site_clients[site] if site_clients.key?(site) && !site_clients[site].nil?

      if disabled_sites.member?(site)
        XxxRename.logger.debug "#{site} is disabled"
        return nil
      end

      site_clients[site] = generate_class(site)
    end

    private

    attr_reader :config, :override_site

    #
    # Find a match for a file using three strategies
    # 1. match a file by original file regex.
    #    this will work for files downloaded from websites
    # 2. match a file with the legacy format used by
    #    the app. this is defined in ProcessedFile by
    #    PROCESSED_FILE_REGEX and FEMALE_FIRST_ID_FILE_REGEX
    # 3. match a file by formats provided in the config
    #
    # @param [String] file
    # @return [Boolean]
    def find_matches(file)
      match_unprocessed?(file) ||
        match_with_legacy_formats?(file) ||
        match_with_source_file_format?(file)
    end

    # @return [Nil, String]
    def override_sc_original_pattern
      @override_sc_original_pattern ||=
        begin
          pattern = nil
          original_file_regexes.map do |i_pattern, i_site_clients|
            i_site_clients.each do |sc|
              if override_site == sc
                pattern = i_pattern
                break
              end
            end
          end
          pattern
        end
    end

    def register_response(site_client_sym, match, unprocessed:)
      return if site_disabled?(site_client_sym)

      site_client = initialise_site_client(site_client_sym)
      @match_response << MatchResponse.new(parsed_info: match, site_client: site_client, unprocessed: unprocessed)
    end

    def disabled_sites
      @disabled_sites ||= Set.new
    end

    def site_clients
      @site_clients ||= {}
    end

    #
    # Generate a reverse lookup of
    # site.{site}.file_source_format -> site
    #
    # This will be used to decide which site client should be used for each file
    #
    # @return [Hash[String->Symbol]]
    def source_file_patterns_to_site
      @source_file_patterns_to_site ||=
        begin
          file_patterns = {}
          site_client_configs = if override_site.nil?
                                  config.site.attributes
                                else
                                  config.site.attributes.select { |site, _| site.to_sym == override_site }
                                end
          site_client_configs.each_pair do |site, site_config|
            site_config.file_source_format.map { |format| file_patterns[format] = site }
          end
          file_patterns
        end
    end

    # @param [String] file
    # @return [Boolean]
    def match_unprocessed?(file)
      unless override_site.nil?
        register_response(override_site, nil, unprocessed: true)
        return true
      end

      original_file_regexes.each_pair do |regex, site_clients|
        next unless (match = file.match(regex))

        site_clients.map do |sc|
          register_response(sc, match, unprocessed: true)
        end
        return true
      end
      false
    end

    # @param [String] file
    # @return [Boolean] List of matching site clients
    def match_with_legacy_formats?(file)
      match = ProcessedFile.parse(file)
      return false unless match.collection_tag.presence

      site_client_sym = config.collection_tag_to_site_client[match.collection_tag]
      return false if site_client_sym.nil?

      register_response(site_client_sym, match, unprocessed: false) if override_site.nil? || override_site == client
    rescue Errors::ParsingError
      false
    end

    # @param [String] file
    # @return [Boolean]
    def match_with_source_file_format?(file)
      matches = []
      source_file_patterns_to_site.each_pair do |format, site_client_sym|
        match = ProcessedFile.strpfile(file, format)
        register_response(site_client_sym, match, unprocessed: false)
        matches << true
      rescue Errors::ParsingError
        matches << false
      end
      matches.any?(TRUE)
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def generate_class(site)
      case site.to_sym
      when :adult_time
        require "xxx_rename/site_clients/adult_time"
        XxxRename::SiteClients::AdultTime.new(config)
      when :babes
        require "xxx_rename/site_clients/babes"
        XxxRename::SiteClients::Babes.new(config)
      when :blacked
        require "xxx_rename/site_clients/blacked"
        XxxRename::SiteClients::Blacked.new(config)
      when :blacked_raw
        require "xxx_rename/site_clients/blacked_raw"
        XxxRename::SiteClients::BlackedRaw.new(config)
      when :brazzers
        require "xxx_rename/site_clients/brazzers"
        XxxRename::SiteClients::Brazzers.new(config)
      when :digital_playground
        require "xxx_rename/site_clients/digital_playground"
        XxxRename::SiteClients::DigitalPlayground.new(config)
      when :elegant_angel
        require "xxx_rename/site_clients/elegant_angel"
        XxxRename::SiteClients::ElegantAngel.new(config)
      when :evil_angel
        require "xxx_rename/site_clients/evil_angel"
        XxxRename::SiteClients::EvilAngel.new(config)
      when :goodporn
        require "xxx_rename/site_clients/goodporn"
        XxxRename::SiteClients::Goodporn.new(config)
      when :jules_jordan
        require "xxx_rename/site_clients/jules_jordan"
        XxxRename::SiteClients::JulesJordan.new(config)
      when :manuel_ferrara
        require "xxx_rename/site_clients/manuel_ferrara"
        XxxRename::SiteClients::ManuelFerrara.new(config)
      when :mofos
        require "xxx_rename/site_clients/mofos"
        XxxRename::SiteClients::Mofos.new(config)
      when :naughty_america
        require "xxx_rename/site_clients/naughty_america"
        XxxRename::SiteClients::NaughtyAmerica.new(config)
      when :nf_busty
        require "xxx_rename/site_clients/nfbusty"
        XxxRename::SiteClients::Nfbusty.new(config)
      when :reality_kings
        require "xxx_rename/site_clients/reality_kings"
        XxxRename::SiteClients::RealityKings.new(config)
      when :stash
        require "xxx_rename/site_clients/stash_db"
        XxxRename::SiteClients::StashDb.new(config)
      when :tushy
        require "xxx_rename/site_clients/tushy"
        XxxRename::SiteClients::Tushy.new(config)
      when :tushy_raw
        require "xxx_rename/site_clients/tushy_raw"
        XxxRename::SiteClients::TushyRaw.new(config)
      when :twistys
        require "xxx_rename/site_clients/twistys"
        XxxRename::SiteClients::Twistys.new(config)
      when :vixen
        require "xxx_rename/site_clients/vixen"
        XxxRename::SiteClients::Vixen.new(config)
      when :whale_media
        require "xxx_rename/site_clients/whale"
        XxxRename::SiteClients::Whale.new(config)
      when :wicked
        require "xxx_rename/site_clients/wicked"
        XxxRename::SiteClients::Wicked.new(config)
      when :x_empire
        require "xxx_rename/site_clients/x_empire"
        XxxRename::SiteClients::XEmpire.new(config)
      when :zero_tolerance
        require "xxx_rename/site_clients/zero_tolerance"
        XxxRename::SiteClients::ZeroTolerance.new(config)
      else
        raise "undefined site: #{site}"
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def original_file_regexes
      @original_file_regexes ||= {}.tap do |h|
        h[Constants::MG_PREMIUM_ORIGINAL_FILE_FORMAT] = %i[babes brazzers digital_playground mofos reality_kings twistys] # babes
        # brazzers; mg premium
        # digital playground; mg premium
        h[Constants::EVIL_ANGEL_ORIGINAL_FILE_PATTERN] = [:evil_angel] # evil angel
        h[Constants::GOODPORN_ORIGINAL_FILE_FORMAT] = [:goodporn] # goodporn
        # mofos; mg premium
        h[Constants::NAUGHTY_AMERICA_ORIGINAL_FILE_REGEX] = [:naughty_america] # naughty america
        h[Constants::NF_BUSTY_ORIGINAL_FILE_REGEX] = [:nf_busty] # nf busty
        # reality kings; mg premium
        # stash; ALWAYS OVERRIDE
        # twistys; mg premium
        h[Constants::VIXEN_MEDIA_ORIGINAL_FILE_REGEX_1] = [:vixen] # vixen
        h[Constants::VIXEN_MEDIA_ORIGINAL_FILE_REGEX_2] = [:vixen]
        h[Constants::WHALE_ORIGINAL_FILE_PATTERN] = [:whale_media] # whale
        # wicked # ALWAYS OVERRIDE
      end
    end
  end
end
