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

    # @param [Boolean] return_raw
    # @param [Integer] current_attempt
    # @param [Integer] max_attempts
    # @param [Proc] block A block that calls the HTTParty request
    # @return [HTTParty::Response]
    # @raise [XxxRename::SiteClients::Errors::APIError]
    def handle_response!(return_raw: false, current_attempt: 1, max_attempts: 5, &block)
      response = block.call

      XxxRename.logger.extra "REQUEST URL:      #{response.request.http_method} #{response.request.path}"
      XxxRename.logger.extra "REQUEST HEADERS:  #{response.request.options[:headers]}"
      XxxRename.logger.extra "REQUEST BODY:     #{response.request.options[:body]}"
      XxxRename.logger.extra "RESPONSE HEADERS: #{response.headers}"
      XxxRename.logger.extra "RESPONSE BODY:    #{response.body.to_s[..200]}"

      if response.code == 200
        return return_raw ? response : response.parsed_response
      end

      err_klass = HTTP_CODE_TO_ERR.fetch(response.code, SiteClients::Errors::UnhandledError)
      raise api_error(err_klass, response)
    rescue *RETRIABLE_ERRORS => e
      raise e if current_attempt > max_attempts

      if e.instance_of?(SiteClients::Errors::TooManyRequestsError)
        XxxRename.logger.error "[RATE LIMIT EXCEEDED] Sleeping for 3 minutes. Cancel to run the app at a different time."
        6.times do |counter|
          sleep(30)
          XxxRename.logger.info "[SLEEP ELAPSED] #{counter * 30}s"
        end
      else
        XxxRename.logger.error "[API ERROR] #{e.class}: message:#{e.message}"
      end
      handle_response!(return_raw: return_raw, current_attempt: current_attempt + 1, max_attempts: max_attempts, &block)
    end

    # @param [Class<AdultTimeDL::APIError>] klass
    # @param [HTTParty::Response] response
    # @return [AdultTimeDL::APIError]
    def api_error(klass, response)
      klass.new(endpoint: response.request.path, code: response.code,
                body: response.parsed_response, headers: response.headers)
    end

    HTTP_CODE_TO_ERR = {
      302 => SiteClients::Errors::RedirectedError,
      400 => SiteClients::Errors::BadRequestError,
      401 => SiteClients::Errors::UnauthorizedError,
      403 => SiteClients::Errors::ForbiddenError,
      404 => SiteClients::Errors::NotFoundError,
      429 => SiteClients::Errors::TooManyRequestsError,
      500 => SiteClients::Errors::InternalServerError,
      503 => SiteClients::Errors::BadGatewayError
    }.freeze

    def resolve_log_level(level)
      return "DEBUG" if level.to_s.upcase == "TRUE"

      ENV.fetch("LOG_LEVEL", "INFO")
    end

    # Attempt to parse a string to Time class. By default it will parse with format %Y-%m-%d
    # @param [String] time_str
    # @param [Array<String>] source_formats
    # @return [Time, Nil]
    def parse_time(time_str, *source_formats)
      return if time_str.nil?

      source_formats << "%Y-%m-%d"
      source_formats.each do |source_format|
        return Time.strptime(time_str, source_format)
      rescue ArgumentError => e
        XxxRename.logger.warn "Error parsing time: #{time_str} with error #{e.message}"
      end
      nil
    end
  end
end
