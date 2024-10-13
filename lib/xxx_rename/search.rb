# frozen_string_literal: true

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

    #
    # Search for a file using datastore or public APIs
    # Optionally, if a block is given, it will be called
    # with the file's matched XxxRename::Data::SceneData
    #
    # @param [String] file
    # @return [Nil,Search::SearchResul]
    def search(file)
      @file = file
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

    attr_reader :file

    def nil_search_result
      @nil_search_result ||= SearchResult.new(scene_data: nil, site_client: nil)
    end

    # @param [Data::MatchResponse] match_response
    def find_by_site_or_datastore(match_response)
      return site_client_search(match_response) if match_response.unprocessed? || force_refresh?

      resp = query_helper.find(match_response.parsed_scene_data,
                               basename: File.basename(file),
                               absolute_path: File.expand_path(file))
      if resp.present?
        XxxRename.logger.info "[DATASTORE LOOKUP SUCCESS] #{resp.title}"
        register_file(resp, file)
        return resp
      end

      site_client_search(match_response)
    end

    # @param [Data::MatchResponse] match_response
    # @return [Nil, Data::SceneData]
    def site_client_search(match_response)
      site_client = match_response.site_client
      result = site_client.search(file,
                                                 parsed_scene_data: match_response.parsed_scene_data,
                                                 unprocessed: match_response.unprocessed)

      if result.nil?
        XxxRename.logger.debug "[NO MATCH SITE CLIENT] #{site_client.class.site_client_name}"
        return
      end

      save_scene_in_datastore(result, file)
      XxxRename.logger.info "[MATCH SUCCESS SITE CLIENT] #{site_client.class.site_client_name}"
      XxxRename.logger.ap result.to_h, :trace
      result
    rescue *NON_FATAL_ERRORS => e
      XxxRename.logger.info "[NO MATCH SITE CLIENT] #{site_client.class.site_client_name}"
      XxxRename.logger.info e.message
      nil
    rescue *SITE_CLIENT_FATAL_ERRORS => e
      XxxRename.logger.error e.message
      matcher.disable_site(site_client)
      nil
    rescue Errors::FatalError => e
      raise e
    end

    # @return [SiteClientMatcher]
    def matcher
      XxxRename.config.site_client_matcher
    end

    # @return [Boolean]
    def force_refresh?
      XxxRename.config.force_refresh
    end

    # @return [Data::SceneDatastoreQuery]
    def scene_datastore
      XxxRename.config.scene_datastore
    end

    # @return [Data::DataStoreQueryHelper]
    def query_helper
      Data::DataStoreQueryHelper.new(scene_datastore)
    end

    def save_scene_in_datastore(scene_data, file)
      scene_datastore.create!(scene_data, force: true)
      register_file(scene_data, file)
    end

    def register_file(scene_data, file)
      XxxRename.logger.trace "[FILENAME REGISTER] #{file} (SCENE) #{scene_data.title}"
      path = File.expand_path(file)
      scene_datastore.register_file(scene_data, path)
    end
  end
end
