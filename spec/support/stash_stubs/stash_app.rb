# frozen_string_literal: true

module StashStubs
  class StashApp
    class << self
      include WebMock::API

      def enable_version_stub
        stub_request(:post, "http://localhost:9999/graphql")
          .with { |request| JSON.parse(request.body)["operationName"] == "Version" }
          .to_return(status: 200, body: "{\"data\":{\"version\":{\"version\":\"v0.18.0\"}}}",
                     headers: { "Content-Type" => "application/json" })
      end

      def enable_scene_paths_by_id_stub(id = 1, title = "Scene Title", paths = ["/absolute/scene/path.mp4"])
        expected_response = {
          "data": {
            "findScene": {
              "id": id.to_s,
              "title": title,
              "files": paths.map { |x| { "path": x} }
            }
          }
        }.to_json
        stub_request(:post, "http://localhost:9999/graphql")
          .with { |request| JSON.parse(request.body)["operationName"] == "FindScene" }
          .to_return(status: 200, body: expected_response,
                     headers: { "Content-Type" => "application/json" })
      end
    end
  end
end

