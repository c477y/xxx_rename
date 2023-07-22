# frozen_string_literal: true

module SiteClientStubs
  class StashDb
    class << self
      include WebMock::API

      def enable_version_stub
        stub_request(:post, %r{https://stashdb.org/graphql})
          .to_return(
            status: 200,
            body: "{\"data\":{\"version\":{\"version\":\"some_version\"}}}",
            headers: { "content-type" => "application/json" }
          )
      end

      def enable_search_scene_stub
        search_resp = File.read(File.join("spec", "fixtures", "stashdb", "search_all.json"))
        stub_request(:post, "https://stashdb.org/graphql")
          .with(body: hash_including("operationName" => "SearchAll"))
          .to_return(status: 200, body: search_resp, headers: { "content-type" => "application/json" })
      end

      def enable_scene_stub
        search_resp = File.read(File.join("spec", "fixtures", "stashdb", "search_scene.json"))
        stub_request(:post, "https://stashdb.org/graphql")
          .with(body: hash_including("operationName" => "Scene"))
          .to_return(status: 200, body: search_resp, headers: { "content-type" => "application/json" })
      end

      def enable_actor_details_stub(actor_name:, gender:)
        res = "{\"data\":{\"searchPerformer\":[{\"name\":\"#{actor_name}\",\"gender\":\"#{gender.upcase}\"}]}}"
        stub_request(:post, %r{https://stashdb.org/graphql})
          .with(body: hash_including("operationName" => "SearchPerformers"))
          .to_return(
            status: 200, body: res,
            headers: { "content-type" => "application/json" }
          )
      end

      def enable_unauthorised_stub(url)
        stub_request(:post, url)
          .to_return(status: 401, body: "")
      end

      def enable_successful_username_login_stub(cookie)
        stub_request(:post, "https://stashdb.org/login")
          .to_return(status: 200, body: "", headers: { "set-cookie" => cookie })
      end
    end
  end
end
