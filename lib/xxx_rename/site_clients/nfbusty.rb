# frozen_string_literal: true

require "nokogiri"
require "xxx_rename"

module XxxRename
  module SiteClients
    class Nfbusty < Base
      include HTTParty

      base_uri "https://nfbusty.com"
      site_client_name :nf_busty

      SCENE_TITLE_REGEX = /^(?<scene_title>^.*)\s-\sS\d*:E\d*$/x.freeze
      PAGE_COUNTER_REGEX = /(?<first>\d+)\sof\s(?<last>\d+)/x.freeze
      FILE_REGEX = /^nfbusty_(?<scene_title>\w*)_\d+\.\w+$/x.freeze

      def search(filename)
        if response.empty?
          XxxRename.logger.info "NFBusty extracts all the scenes before matching. This process may take some time.".colorize(:red)
          fetch_all_scenes
        end

        scene_match = filename.match(FILE_REGEX)
        raise Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_METADATA, filename) if scene_match.nil?

        title = scene_match[:scene_title].normalize
        @response[title] || raise(Errors::NoMatchError.new(Errors::NoMatchError::ERR_NO_RESULT, filename))
      end

      private

      def response
        @response ||= {}
      end

      def last_page?(doc)
        page_text = doc.css(".dropdown-toggle").text.strip
        match = page_text.match PAGE_COUNTER_REGEX
        raise "Unable to parse page counter" if match.nil?

        true if match[:first] == match[:last]
      end

      def fetch_all_scenes(page = 0)
        XxxRename.logger.debug "Fetching Page #{"#".to_s.colorize(:blue) + page.to_s.colorize(:blue)}."

        doc = Nokogiri::HTML request_video_html(page)
        doc.css(".content-grid").css(".row").css(".content-grid-item").each do |element|
          full_title = element.css(".caption-header").css(".title").text.strip
          matched_title = full_title.match(SCENE_TITLE_REGEX)
          next if matched_title.nil?

          title = matched_title[:scene_title]
          XxxRename.logger.debug("Extracted Scene #{title.to_s.colorize(:blue)}")
          normalized_title = title.normalize

          @response[normalized_title] = Data::SceneData.new(
            {
              collection: "NFBusty",
              collection_tag: "NF",
              title: title,
              id: nil,
              date_released: Time.strptime(element.css(".date").text.strip, "%b %e, %Y")
            }.merge(actors_hash(element.css(".models").css(".model").map { |model| model.text.strip }))
          )
        end
        return if last_page?(doc)

        fetch_all_scenes(page + 1)
      end

      # @param [Integer] page
      def request_video_html(page)
        resp = self.class.get("/video/gallery/#{page * 12}").body
        case resp.code
        when 200 then resp
        when 503 then raise SiteClients::Errors::SiteClientUnavailableError, self.class.base_uri
        else raise "Something went wrong #{resp.code}"
        end
      end
    end
  end
end
