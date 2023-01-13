# frozen_string_literal: true

module SiteClientStubs
  class Brazzers
    include WebMock::API

    def initialize(*stubs)
      WebMock.enable!
      if stubs.empty?
        stub_actor_search
      else
        stubs.each { |x| send("stub_#{x}".to_sym) }
      end
    end

    def cleanup
      remove_request_stub(@stub_actor_search) if @stub_actor_search
    end

    def stub_actor_search
      search_results = File.read(File.join("spec", "fixtures", "brazzers", "actor_search.json"))
      @stub_actor_search = stub_request(:get, %r{https://site-api.project1service.com/v1/actors})
                           .to_return(status: 200,
                                      headers: { "Content-Type" => "application/json; charset=utf-8" },
                                      body: search_results)
    end
  end
end
