# frozen_string_literal: true

module XxxRename
  class SiteClientMatcher
    #
    # Find a match for a file using three strategies
    # 1. match a file by original file regex.
    #    this will work for files downloaded from websites
    # 2. match a file by formats provided in the config
    #
    # @param [String] file
    # @return [Array[Data::MatchResponse]]
    def match(file)
      match_arr = match_unprocessed?(file).compact
      unless match_arr.empty?
        XxxRename.logger.trace "[MATCHED AS UNPROCESSED FILE] #{file}"
        return match_arr
      end

      match_arr = match_with_source_file_format?(file).compact
      unless match_arr.empty?
        XxxRename.logger.trace "[MATCHED FILE USING SOURCE FILE FORMAT] #{file}"
        return match_arr
      end

      XxxRename.logger.trace "[NO STRATEGIES MATCHED FILE TO SITE CLIENT] #{file}"
      []
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
        XxxRename.logger.debug "[SITE CLIENT DISABLED] #{site}"
        return nil
      end

      site_clients[site] = generate_class(site)
    end

    private

    SYM_TO_SITE_CLIENT = {
      adult_time: SiteClients::AdultTime,
      arch_angel: SiteClients::ArchAngelVideo,
      babes: SiteClients::Babes,
      blacked: SiteClients::Blacked,
      blacked_raw: SiteClients::BlackedRaw,
      brazzers: SiteClients::Brazzers,
      digital_playground: SiteClients::DigitalPlayground,
      deeper: SiteClients::Deeper,
      elegant_angel: SiteClients::ElegantAngel,
      evil_angel: SiteClients::EvilAngel,
      goodporn: SiteClients::Goodporn,
      jules_jordan: SiteClients::JulesJordan,
      manuel_ferrara: SiteClients::ManuelFerrara,
      mofos: SiteClients::Mofos,
      naughty_america: SiteClients::NaughtyAmerica,
      nf_busty: SiteClients::Nfbusty,
      reality_kings: SiteClients::RealityKings,
      stash: SiteClients::StashDb,
      tushy: SiteClients::Tushy,
      tushy_raw: SiteClients::TushyRaw,
      twistys: SiteClients::Twistys,
      vixen: SiteClients::Vixen,
      whale_media: SiteClients::Whale,
      wicked: SiteClients::Wicked,
      x_empire: SiteClients::XEmpire,
      zero_tolerance: SiteClients::ZeroTolerance
    }.freeze

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

    # @param [Symbol] site_client_sym
    # @param [Data::ParsedSceneData] parsed_scene_data
    # @param [String] file
    # @param [Boolean] unprocessed
    # @return [Data::MatchResponse]
    # noinspection RubyMismatchedReturnType
    def register_response(site_client_sym, parsed_scene_data, file, unprocessed:)
      return if site_disabled?(site_client_sym)

      site_client = initialise_site_client(site_client_sym)
      Data::MatchResponse.new(parsed_scene_data: parsed_scene_data,
                              site_client: site_client,
                              unprocessed: unprocessed,
                              filename: file)
    end

    def disabled_sites
      @disabled_sites ||= Set.new
    end

    def site_clients
      @site_clients ||= {}
    end

    # @param [String] file
    # @return [Array<Data::MatchResponse>]
    def match_unprocessed?(file)
      original_file_regexes.each_pair do |regex, site_clients|
        # Skip if override_site is set and the site is not included for the regex
        next if override_site.present? && site_clients.exclude?(override_site.to_sym)

        # Skip if there's no match
        next unless (match = file.match(regex))

        parsed_scene_data = parse_scene_data_from_original_file(match)
        return site_clients.map do |site_client|
          register_response(site_client, parsed_scene_data, file, unprocessed: true)
        end
      end

      []
    end

    # @param [MatchData] match
    # @return [Data::ParsedSceneData]
    # noinspection RubyMismatchedArgumentType,RubyMismatchedReturnType
    def parse_scene_data_from_original_file(match)
      prepared_match = match.named_captures.tap do |h|
        re = /[&_-]/
        h["actors"] = h["actors"]&.split(re)
        h["female_actors"] = h["female_actors"]&.split(re)
        h["male_actors"] = h["male_actors"]&.split(re)
      end

      XxxRename.logger.ap prepared_match, :extra

      Data::ParsedSceneData.new(prepared_match)
    end

    # @param [String] file
    # @return [Array<Data::MatchResponse>]
    def match_with_source_file_format?(file)
      match_data_arr = []
      source_file_patterns_to_site.each_pair do |format, site_client_sym|
        match = ProcessedFile.strpfile(file, format)
        XxxRename.logger.trace "[REGEX MATCH]\n" \
                                 "\t FORMAT: #{format}\n" \
                                 "\t #{match.to_compact_h}"

        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, file) if match.blank?

        match_data_arr << register_response(site_client_sym, match, file, unprocessed: false)
      rescue Errors::ParsingError => e
        XxxRename.logger.trace "[REGEX PARSING FAIL] #{e.message}"
      end
      match_data_arr
    end

    # @param [Symbol] site
    # @return [XxxRename::SiteClients::Base]
    def generate_class(site)
      raise "undefined site: #{site}" if SYM_TO_SITE_CLIENT[site].nil?

      SYM_TO_SITE_CLIENT[site].new
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

          XxxRename.logger.trace "[SOURCE FILE FORMAT(s) TO SITE CLIENT]"
          XxxRename.logger.ap file_patterns, :extra
          file_patterns
        end
    end

    def original_file_regexes
      @original_file_regexes ||= {}.tap do |h|
        h[Constants::MG_PREMIUM_ORIGINAL_FILE_FORMAT] =
          %i[babes brazzers digital_playground mofos reality_kings twistys]
        # babes; mg premium
        # brazzers; mg premium
        # digital playground; mg premium
        h[Constants::EVIL_ANGEL_ORIGINAL_FILE_PATTERN] = %i[evil_angel x_empire wicked] # evil angel
        h[Constants::GOODPORN_ORIGINAL_FILE_FORMAT] = [:goodporn] # goodporn
        # mofos; mg premium
        # NaughtyAmerica is disabled
        # h[Constants::NAUGHTY_AMERICA_ORIGINAL_FILE_REGEX] = [:naughty_america] # naughty america
        h[Constants::NF_BUSTY_ORIGINAL_FILE_REGEX] = [:nf_busty] # nf busty
        # reality kings; mg premium
        # stash; ALWAYS OVERRIDE
        # twistys; mg premium
        h[Constants::VIXEN_MEDIA_ORIGINAL_FILE_REGEX_1] = [:vixen] # vixen
        h[Constants::VIXEN_MEDIA_ORIGINAL_FILE_REGEX_2] = [:vixen]
        h[Constants::WHALE_ORIGINAL_FILE_PATTERN] = [:whale_media] # whale
        # wicked; evil-angel
      end
    end

    # @return [Data::Config]
    def config
      XxxRename.config
    end

    # @return [String]
    def override_site
      config.override_site
    end
  end
end
