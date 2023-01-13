# frozen_string_literal: true

module SiteClientStubs
  class VixenMedia
    include WebMock::API

    def initialize(*stubs)
      WebMock.enable!
      if stubs.empty?
        stub_tushy_search_ok
      else
        stubs.each { |x| send("stub_#{x}".to_sym) }
      end
    end

    def cleanup
      remove_request_stub(@stub_tushy_search_ok) if @stub_tushy_search_ok
    end

    def stub_tushy_search_ok
      search_results = File.read(File.join("spec", "fixtures", "vixen_media", "search_results_tushy_seal_deal.json"))
      @stub_tushy_search_ok = stub_request(:post, "https://www.tushy.com/graphql")
                              .to_return(status: 200,
                                         headers: { "Content-Type" => "application/json; charset=utf-8" },
                                         body: search_results)
    end
  end
end
