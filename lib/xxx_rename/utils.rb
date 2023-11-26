# frozen_string_literal: true

require "net/protocol"
require "openssl"

module XxxRename
  module Utils
    #
    # Accept an array of strings which make up the scene name
    # The function returns a string where the elements which make
    # up one word are joined together.
    #
    def adjust_apostrophe(arr)
      # Convert the hyphen to spaces for easier searching
      apostrophe_chars = %w[t s d ve ll re m ve]
      resp = []
      arr.each_with_index do |e, i|
        next if apostrophe_chars.include? e

        resp << if apostrophe_chars.include? arr[i + 1]
                  [e, arr[i + 1]].join("'")
                else
                  e
                end
      end
      resp.join(" ")
    end

    RETRIABLE_ERRORS = [
      Net::OpenTimeout,
      Net::ReadTimeout,
      OpenSSL::SSL::SSLError,
      SiteClients::Errors::TooManyRequestsError
    ].freeze

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    # @param [HTTParty::Response|NilClass] net_response
    # @param [Boolean] return_raw
    # @param [Integer] current_attempt
    # @param [Integer] max_attempts
    def handle_response!(return_raw: false, current_attempt: 1, max_attempts: 5, &block)
      raise ArgumentError, "expected HTTParty::Response or Proc, invoked with nil" unless block

      response = block.call

      case response.code
      when 200 then return_raw ? response : response.parsed_response
      when 302 then raise api_error(SiteClients::Errors::RedirectedError, response)
      when 400 then raise api_error(SiteClients::Errors::BadRequestError, response)
      when 401 then raise api_error(SiteClients::Errors::UnauthorizedError, response)
      when 403 then raise api_error(SiteClients::Errors::ForbiddenError, response)
      when 429 then raise api_error(SiteClients::Errors::TooManyRequestsError, response)
      when 404 then raise api_error(SiteClients::Errors::NotFoundError, response)
      when 500 then raise api_error(SiteClients::Errors::InternalServerError, response)
      when 503 then raise api_error(SiteClients::Errors::BadGatewayError, response)
      else raise api_error(SiteClients::Errors::UnhandledError, response)
      end
    rescue *RETRIABLE_ERRORS => e
      raise e if current_attempt > max_attempts

      if e.instance_of?(SiteClients::Errors::TooManyRequestsError)
        XxxRename.logger.error "[RATE LIMIT EXCEEDED] Sleeping for 3 minutes. Cancel to run the app at a different time."
        6.times do |counter|
          sleep(30)
          XxxRename.logger.info "[SLEEP ELAPSED] #{counter * 30}s"
        end
      else
        XxxRename.logger.error "#{e.class}: message:#{e.message}"
      end
      handle_response!(return_raw: return_raw, current_attempt: current_attempt + 1, max_attempts: max_attempts, &block)
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    # @param [Class<AdultTimeDL::APIError>] klass
    # @param [HTTParty::Response] response
    # @return [AdultTimeDL::APIError]
    def api_error(klass, response)
      endpoint = "#{response.request.base_uri}#{response.request.path}"
      klass.new(endpoint: endpoint, code: response.code,
                body: response.parsed_response, headers: response.headers)
    end

    def resolve_log_level(level)
      return "DEBUG" if level.is_a?(Boolean)

      ENV.fetch("LOG_LEVEL", "INFO")
    end
  end
end
