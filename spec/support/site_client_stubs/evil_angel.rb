# frozen_string_literal: true

require "webmock"

module SiteClientStubs
  class EvilAngel
    include WebMock::API

    def initialize(*stubs)
      stub(*stubs)
    end

    def stub(*stubs)
      if stubs.empty?
        stub_login
        stub_search
        stub_no_results_search
        stub_movie_search
      else
        stubs.each { |x| send("stub_#{x}".to_sym) }
      end
    end

    def stub_login
      stub_request(:get, "https://www.evilangel.com:443/")
        .to_return(status: 301,
                   headers: { "Location" => "/en/?s=1",
                              "Content-Type" => "text/html; charset=UTF-8" })

      homepage = File.read(File.join("spec", "fixtures", "evil_angel", "homepage.html"))

      stub_request(:get, "https://www.evilangel.com:443/en/?s=1")
        .to_return(status: 200,
                   headers: { "Content-Type" => "text/html; charset=utf-8" },
                   body: homepage)
    end

    def stub_search
      search_results = File.read(File.join("spec", "fixtures", "evil_angel", "search_results_stunning_curves.json"))
      stub_request(:post, %r{/1/indexes/all_scenes/query})
        .to_return(status: 200,
                   headers: { "Content-Type" => "application/json; charset=UTF-8" },
                   body: search_results)
    end

    def stub_movie_search
      search_results = File.read(File.join("spec", "fixtures", "evil_angel", "movie_search_results.json"))
      stub_request(:post, %r{/1/indexes/all_movies/query})
        .to_return(status: 200,
                   headers: { "Content-Type" => "application/json; charset=UTF-8" },
                   body: search_results)
    end

    def stub_no_results_search
      search_results = File.read(File.join("spec", "fixtures", "evil_angel", "search_results_empty_set.json"))
      stub_request(:post, %r{/1/indexes/all_scenes/query})
        .to_return(status: 200,
                   headers: { "Content-Type" => "application/json; charset=UTF-8" },
                   body: search_results)
    end

    def stub_service_unavailable
      stub_request(:post, %r{/1/indexes/all_scenes/query}).to_return(status: 503)
    end
  end
end
