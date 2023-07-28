# frozen_string_literal: true

module XxxRename
  module Data
    # SiteClientMetaData is only used by sites that need to scrape
    # data from the website before it can match any scenes
    class SiteClientMetaData < Base
      # Set when a site client has completely scraped all required
      # data from the website
      attribute :complete, Types::Bool.default(false)

      # The first URL that is processed by a site client
      # This will be useful when the site client can conditionally
      # check if a datastore refresh is required based on the latest
      # url it scrapes from the website and what is stored in the
      # metadata
      attribute :latest_url, Types::String

      attribute? :failure do
        attribute :checkpoint, Types::String
      end

      class << self
        def create(latest_url)
          new(
            {
              complete: false,
              latest_url: latest_url
            }
          )
        end
      end

      # @return [Boolean]
      def complete?
        complete
      end

      # @return [Boolean]
      def failure?
        failure.presence
      end

      def mark_complete
        new(
          {
            complete: true,
            latest_url: latest_url
          }
        )
      end

      def register_failure(checkpoint:)
        new(
          {
            complete: false,
            latest_url: latest_url,
            failure: {
              checkpoint: checkpoint
            }
          }
        )
      end
    end
  end
end
