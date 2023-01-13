# frozen_string_literal: true

require "xxx_rename/site_clients/errors"
require "xxx_rename/constants"
require "awesome_print"
require "algolia/error"

module XxxRename
  class Search
    include FileUtilities

    SearchResult = Struct.new(:scene_data, :site_client, keyword_init: true) do
      def success?
        scene_data && site_client
      end

      def empty?
        scene_data.nil? && site_client.nil?
      end
    end

    NON_FATAL_ERRORS = [
      SiteClients::Errors::NoMatchError,
      SiteClients::Errors::SearchError,
      SiteClients::Errors::NotFoundError,
      SiteClients::Errors::RedirectedError,
      SiteClients::Errors::BadRequestError
    ].freeze

    SITE_CLIENT_FATAL_ERRORS = [
      SiteClients::Errors::SiteClientUnavailableError,
      SiteClients::Errors::InvalidCredentialsError,
      SiteClients::Errors::ForbiddenError,
      SiteClients::Errors::BadGatewayError,
      SiteClients::Errors::UnhandledError,
      SiteClients::Errors::UnauthorizedError,
      SiteClients::Errors::TooManyRequestsError,
      Algolia::AlgoliaUnreachableHostError,
      Algolia::AlgoliaHttpError
    ].freeze

    # @param [XxxRename::SiteClientMatcher] matcher
    # @param [XxxRename::Data::SceneDatastoreQuery] scene_datastore
    def initialize(matcher, scene_datastore, force_refresh)
      @matcher = matcher
      @scene_datastore = scene_datastore
      @force_refresh = force_refresh
    end

    #
    # Search for a file using datastore or public APIs
    # Optionally, if a block is given, it will be called
    # with the file's matched XxxRename::Data::SceneData
    #
    # @param [String] file
    # @return [Nil|[XxxRename::Search::SearchResult]]
    def search(file)
      @file = File.basename(file)
      match_responses = matcher.match(@file)
      search_result = nil

      match_responses.each do |match_response|
        scene_data = find_by_site_or_datastore(match_response)
        unless scene_data.nil?
          search_result = SearchResult.new(scene_data: scene_data, site_client: match_response.site_client)
          break
        end
      end

      if search_result.nil?
        block_given? ? yield(nil_search_result) : nil_search_result
      else
        XxxRename.logger.ap search_result.scene_data
        block_given? ? yield(search_result) : search_result
      end
    end

    private

    attr_reader :matcher, :scene_datastore, :file

    def nil_search_result
      @nil_search_result ||= SearchResult.new(scene_data: nil, site_client: nil)
    end

    def find_by_site_or_datastore(match_response)
      return site_client_search(match_response.site_client, file) if match_response.unprocessed == true || @force_refresh

      if (resp = scene_datastore.find_by_abs_path?(abs_path!(@file)))
        XxxRename.logger.info "#{"[FILENAME LOOKUP SUCCESS]".colorize(:green)} #{resp.title}"
        return resp
      end

      if (resp = find_in_datastore(match_response.parsed_info))
        XxxRename.logger.info "#{"[MATCH SUCCESS DATASTORE]".colorize(:green)} #{resp.title}"
        register_file(resp, file)
        return resp
      end

      site_client_search(match_response.site_client, file)
    end

    def site_client_search(site_client, file)
      result = site_client.search(file)
      if result.nil?
        XxxRename.logger.info "#{"[NO MATCH SITE CLIENT]".colorize(:yellow)} #{site_client.class.site_client_name}"
        return
      end

      save_scene_in_datastore(result, file)
      XxxRename.logger.info "#{"[MATCH SUCCESS SITE CLIENT]".colorize(:green)} #{site_client.class.site_client_name}"
      result
    rescue *NON_FATAL_ERRORS => e
      XxxRename.logger.info "#{"[NO MATCH SITE CLIENT]".colorize(:yellow)} #{site_client.class.site_client_name}"
      XxxRename.logger.debug e.message
      nil
    rescue *SITE_CLIENT_FATAL_ERRORS => e
      XxxRename.logger.error e.message
      matcher.disable_site(site_client)
      nil
    rescue Errors::FatalError => e
      raise e
    end

    def save_scene_in_datastore(scene_data, file)
      scene_datastore.create!(scene_data, force: true)
      register_file(scene_data, file)
    end

    def register_file(scene_data, file)
      XxxRename.logger.debug "[FILENAME REGISTER] #{file} (SCENE) #{scene_data.title}"
      path = abs_path!(file)
      scene_datastore.register_file(scene_data, path)
    end

    def find_in_datastore(parsed_info)
      find_by_metadata?(parsed_info) || find_by_key?(parsed_info)
    end

    def abs_path!(file)
      path = File.expand_path(file)
      raise "expanded path #{path} invalid" unless valid_file?(path)

      path
    end

    def find_by_key?(parsed_info)
      key = parsed_info&.key
      key.nil? ? nil : scene_datastore.find_by_key?(key)
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def find_by_metadata?(parsed_info)
      collection_tag = parsed_info.collection_tag.presence
      if collection_tag && (id = parsed_info.id&.presence)
        scene_datastore.find(collection_tag: collection_tag, id: id)&.first
      elsif collection_tag && parsed_info.title
        scene_datastore.find(collection_tag: collection_tag, title: parsed_info.title)&.first
      elsif parsed_info.title && parsed_info.actors
        resp = scene_datastore.find(title: parsed_info.title, actors: parsed_info.actors)
        return resp.first if resp && resp.length == 1
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  end
end
