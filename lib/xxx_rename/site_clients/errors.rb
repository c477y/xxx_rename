# frozen_string_literal: true

module XxxRename
  module SiteClients
    module Errors
      class NoMatchError < StandardError
        attr_reader :code, :data

        ERR_NO_METADATA = 0
        ERR_NO_RESULT = 1
        ERR_NW_REDIRECT = 2
        ERR_CUSTOM = 3

        def initialize(code, data)
          @code = code
          @data = data
          super(make_message)
        end

        def make_message
          case code
          when ERR_NO_RESULT then "No results from API #{"using query #{data}" if data}"
          when ERR_NO_METADATA then "No metadata parsed from file"
          when ERR_NW_REDIRECT then "Network redirect from search #{data}"
          when ERR_CUSTOM then data || "No metadata parsed from file"
          else "Unhandled error when trying to process file (Code #{code})"
          end
        end
      end

      class SiteClientUnavailableError < StandardError
        def initialize(site)
          super("Network #{site} unreachable. Check if site is accessible.")
        end
      end

      class InvalidCredentialsError < StandardError
        def initialize(site)
          super("Missing/Invalid credentials provided for #{site}")
        end
      end

      class SearchError < StandardError
        attr_reader :entity, :request_options, :response_code, :response_body

        def initialize(entity, object)
          @entity = entity
          @request_options = object[:request_options]
          @response_code = object[:response_code]
          @response_body = object[:response_body]
          super("Network Error while fetching details for file #{@entity}")
        end

        def dump_error
          File.open(File.join($pwd, "error_dump.txt"), "a") do |dump| # rubocop:disable Style/GlobalVars
            dump << "--------ERROR BEGIN--------\n#{message}\n"
            dump << "--------ENTITY--------\n#{@entity}\n"
            dump << "--------REQUEST--------\n#{@request_options}\n"
            dump << "--------CODE--------\n#{@response_code}\n"
            dump << "--------BODY--------\n#{@response_body}\n"
            dump << "--------ERROR END--------\n\n\n"
          end
        end
      end

      class APIError < StandardError
        attr_reader :endpoint, :code, :body, :headers

        def initialize(endpoint:, code:, body:, headers:)
          @endpoint = endpoint
          @code = code
          @body = body
          @headers = headers
          super(message)
        end

        def fetch_error_message
          case code
          when 302 then "unexpected redirection to #{headers["location"]}"
          else (body&.[]("error") || body&.[]("message") || body).to_s[0..150]
          end
        end

        def message
          "API Failure:\n" \
          "\tURL: #{endpoint}\n" \
          "\tRESPONSE CODE: #{code}\n" \
          "\tERROR MESSAGE: #{fetch_error_message}"
        end
      end

      class BadGatewayError < APIError; end
      class BadRequestError < APIError; end
      class ForbiddenError < APIError; end
      class InternalServerError < APIError; end
      class NotFoundError < APIError; end
      class RedirectedError < APIError; end
      class TooManyRequestsError < APIError; end
      class UnauthorizedError < APIError; end
      class UnhandledError < APIError; end
    end
  end
end
