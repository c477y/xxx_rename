# frozen_string_literal: true

require "rspec"
require "xxx_rename/integrations/stash_app"

describe XxxRename::Integrations::StashApp do
  let(:stash_url) { "http://localhost:9999" }

  describe ".setup_credentials!" do
    subject(:call) { described_class.new(config).setup_credentials! }

    context "when no credentials are provided" do
      include_context "config provider" do
        let(:override_config) { { "stash_app" => { "url" => stash_url } } }
      end

      context "and stash app does not require any credentials" do
        before do
          stub_request(:post, "#{stash_url}/graphql")
            .with do |request|
            body = JSON.parse(request.body)
            body["operationName"] == "Version"
          end.to_return(status: 200, body: "{\"data\":{\"version\":{\"version\":\"v0.18.0\"}}}",
                        headers: { "Content-Type" => "application/json" })
        end

        it "return the version" do
          expect(call).to eq("v0.18.0")
        end
      end

      context "and stash app requires credentials" do
        before do
          stub_request(:post, "#{stash_url}/graphql")
            .with do |request|
            body = JSON.parse(request.body)
            body["operationName"] == "Version"
          end.to_return(status: 401, body: "", headers: { "Content-Type" => "application/json" })
        end

        it "raises unauthorised error" do
          expect { call }.to raise_error(XxxRename::SiteClients::Errors::UnauthorizedError)
        end
      end
    end

    context "when credentials are provided" do
      let(:api_token) { "token" }

      include_context "config provider" do
        let(:override_config) { { "stash_app" => { "url" => stash_url, "api_token" => api_token } } }
      end

      context "correct credentials" do
        before do
          stub_request(:post, "#{stash_url}/graphql")
            .with do |request|
            body = JSON.parse(request.body)
            body["operationName"] == "Version"
          end.to_return(status: 200, body: "{\"data\":{\"version\":{\"version\":\"v0.18.0\"}}}",
                        headers: { "Content-Type" => "application/json" })
        end

        it "return the version" do
          expect(call).to eq("v0.18.0")
        end
      end

      context "incorrect credentials" do
        before do
          stub_request(:post, "#{stash_url}/graphql")
            .with do |request|
            body = JSON.parse(request.body)
            body["operationName"] == "Version"
          end.to_return(status: 500, body: "unauthorized", headers: { "Content-Type" => "text/plain" })
        end

        it "raises error" do
          expect { call }.to raise_error(XxxRename::SiteClients::Errors::InternalServerError)
        end
      end
    end
  end

  describe ".fetch_studio" do
    subject(:call) { described_class.new(config).fetch_studio(name) }

    include_context "config provider" do
      let(:override_config) { { "stash_app" => { "url" => stash_url } } }
    end

    before do
      stub_request(:post, "#{stash_url}/graphql").with do |request|
        body = JSON.parse(request.body)
        body["operationName"] == "FindStudios"
      end.to_return(status: 200,
                    body: "{\"data\":{\"findStudios\":{\"studios\":[{\"id\":\"1\",\"name\":\"bar baz\"}]}}}",
                    headers: { "Content-Type" => "application/json" })
    end

    context "when studio exists" do
      let(:name) { "bar baz" }
      let(:expected_response) do
        {
          "id" => "1",
          "name" => "bar baz"
        }
      end

      it "return the studio" do
        expect(call).to eq(expected_response)
      end
    end

    context "when studio does not exists" do
      let(:name) { "foobar" }
      let(:expected_response) { nil }

      it "return the studio" do
        expect(call).to eq(expected_response)
      end
    end
  end

  describe ".fetch_movie" do
    subject(:call) { described_class.new(config).fetch_movie(name) }

    include_context "config provider" do
      let(:override_config) { { "stash_app" => { "url" => stash_url } } }
    end

    before do
      body = {
        "data" => {
          "findMovies" => {
            "movies" => [
              {
                "id" => "2",
                "name" => "movie name that exists",
                "scenes" => [
                  {
                    "id" => "1234",
                    "title" => "scene name",
                    "path" => "absolute/path/of/scene.ext"
                  }
                ]
              }
            ]
          }
        }
      }.to_json

      stub_request(:post, "#{stash_url}/graphql").with do |request|
        body = JSON.parse(request.body)
        body["operationName"] == "FindMovies"
      end.to_return(status: 200,
                    body: body,
                    headers: { "Content-Type" => "application/json" })
    end

    context "when movie exists" do
      let(:name) { "movie name that exists" }
      let(:expected_response) do
        {
          "id" => "2",
          "name" => "movie name that exists",
          "scenes" => [
            {
              "id" => "1234",
              "title" => "scene name",
              "path" => "absolute/path/of/scene.ext"
            }
          ]
        }
      end

      it "return the movie" do
        expect(call).to eq(expected_response)
      end
    end

    context "when movie does not exists" do
      let(:name) { "foobar" }
      let(:expected_response) { nil }

      it "return the movie" do
        expect(call).to eq(expected_response)
      end
    end
  end

  describe ".create_movie" do
    subject(:call) { described_class.new(config).create_movie(scene_data, studio_id) }

    let(:scene_data) do
      XxxRename::Data::SceneData.new(
        female_actors: ["Angela White", "Gianna Dior"],
        male_actors: ["Ramon Nomar"],
        actors: ["Angela White", "Gianna Dior", "Ramon Nomar"],
        collection: "Blockbuster",
        collection_tag: "DP",
        title: "Exposure: Scene 3",
        id: "4395046",
        date_released: Time.parse("2019-09-25T00:00:00+00:00"),
        movie: {
          name: "Exposure",
          date: Time.parse("2019-09-25T00:00:00+00:00"),
          url: "https://www.digitalplayground.com/movie/4395043/exposure",
          front_image: "https://media-public-ht.project1content.com/m=eIAbaWhWx/634/d2a/485/56c/4e0/4be/0e4/282/bca/b53/c4/cover/cover_01.jpg",
          studio: "Digital Playground"
        }
      )
    end
    let(:studio_id) { nil }

    include_context "config provider" do
      let(:override_config) { { "stash_app" => { "url" => stash_url } } }
    end

    context "when called with valid input" do
      before do
        body = {
          "data" => {
            "movieCreate" => {
              "id" => "1",
              "name" => "Exposure",
              "duration" => nil,
              "date" => "2019-09-25",
              "director" => nil,
              "studio" => nil,
              "synopsis" => nil,
              "url" => "https://www.digitalplayground.com/movie/4395043/exposure",
              "front_image_path" => "#{stash_url}/movie/1/frontimage?1672612919",
              "back_image_path" => nil
            }
          }
        }.to_json

        stub_request(:post, "#{stash_url}/graphql").with do |request|
          body = JSON.parse(request.body)
          body["operationName"] == "MovieCreate"
        end.to_return(status: 200,
                      body: body,
                      headers: { "Content-Type" => "application/json" }).then.to_return(
                        status: 200,
                        body: { "data" => { "movieCreate" => nil },
                                "errors" => [{ "message" => "UNIQUE constraint failed: movies.checksum", "path" => ["movieCreate"] }] }.to_json,
                        headers: { "Content-Type" => "application/json" }
                      )
      end

      let(:expected_response) do
        {
          "id" => "1",
          "name" => "Exposure",
          "duration" => nil,
          "date" => "2019-09-25",
          "director" => nil,
          "studio" => nil,
          "synopsis" => nil,
          "url" => "https://www.digitalplayground.com/movie/4395043/exposure",
          "front_image_path" => "#{stash_url}/movie/1/frontimage?1672612919",
          "back_image_path" => nil
        }
      end

      it "creates the movie" do
        expect(call).to eq(expected_response)
      end

      it "does not create the movie again" do
        # create movie once
        described_class.new(config).create_movie(scene_data, studio_id)
        expect { call }.to raise_error(XxxRename::Integrations::StashAPIError, /Stash API returned error/)
      end
    end
  end

  describe ".fetch_scene" do
    subject(:call) { described_class.new(config).fetch_scene(path) }

    include_context "config provider" do
      let(:override_config) { { "stash_app" => { "url" => stash_url } } }
    end

    before do
      body = {
        "data" => {
          "findScenes" => {
            "scenes" => [
              {
                "id" => "1",
                "title" => "Scene Title",
                "files" => [
                  {
                    "path" => "/aboslute/path/to/scene.mp4"
                  }
                ],
                "movies" => [
                  {
                    "movie" => {
                      "id" => "1",
                      "name" => "Movie",
                      "front_image_path" => "https://#{stash_url}/movie/3/frontimage?1659996626"
                    },
                    "scene_index" => nil
                  }
                ]
              }
            ]
          }
        }
      }.to_json

      stub_request(:post, "#{stash_url}/graphql").with do |request|
        body = JSON.parse(request.body)
        body["operationName"] == "FindScenes"
      end.to_return(status: 200,
                    body: body,
                    headers: { "Content-Type" => "application/json" })
    end

    context "when scene exists" do
      let(:path) { "/aboslute/path/to/scene.mp4" }

      let(:expected_response) do
        {
          "id" => "1",
          "title" => "Scene Title",
          "files" => [
            {
              "path" => "/aboslute/path/to/scene.mp4"
            }
          ],
          "movies" => [
            {
              "movie" => {
                "id" => "1",
                "name" => "Movie",
                "front_image_path" => "https://#{stash_url}/movie/3/frontimage?1659996626"
              },
              "scene_index" => nil
            }
          ]
        }
      end

      it "returns the scene" do
        expect(call).to eq(expected_response)
      end
    end
  end

  describe ".fetch_scene_by_id_body" do
    subject(:call) { described_class.new(config).fetch_scene_by_id(id) }

    include_context "config provider" do
      let(:override_config) { { "stash_app" => { "url" => stash_url } } }
    end

    before do
      body = {
        "data" => {
          "findScene" => {
            "id" => "1",
            "title" => "",
            "files" => [
              { "path" => "path_to_file" }
            ]
          }
        }
      }.to_json

      stub_request(:post, "#{stash_url}/graphql").with do |request|
        body = JSON.parse(request.body)
        body["operationName"] == "FindScene"
      end.to_return(status: 200,
                    body: body,
                    headers: { "Content-Type" => "application/json" })
    end

    context "when scene exists" do
      let(:id) { "1" }

      let(:expected_response) do
        {
          "id" => "1",
          "title" => "",
          "files" => [
            { "path" => "path_to_file" }
          ]
        }
      end

      it "returns the scene" do
        expect(call).to eq(expected_response)
      end
    end
  end

  describe ".update_scene" do
    subject(:call) { described_class.new(config).update_scene(scene_id, movie_id) }

    include_context "config provider" do
      let(:override_config) { { "stash_app" => { "url" => stash_url } } }
    end

    let(:scene_id) { "1" }
    let(:movie_id) { "99" }

    context "when both scene and movie exist" do
      before do
        body = { "data" =>
                   { "sceneUpdate" =>
                       { "id" => "1",
                         "title" => "scene title",
                         "files" => [{ "path" => "absolute/path/to/scene.ext" }],
                         "movies" => [{
                           "movie" => { "id" => "99",
                                        "name" => "movie name",
                                        "front_image_path" => "https://#{stash_url}/movie/3/frontimage?1234" }, "scene_index" => nil
                         }] } } }.to_json

        stub_request(:post, "#{stash_url}/graphql").with do |request|
          body = JSON.parse(request.body)
          body["operationName"] == "SceneUpdate"
        end.to_return(status: 200,
                      body: body,
                      headers: { "Content-Type" => "application/json" })
      end

      let(:expected_response) do
        { "id" => "1",
          "title" => "scene title",
          "files" => [{ "path" => "absolute/path/to/scene.ext" }],
          "movies" => [{
            "movie" => { "id" => "99",
                         "name" => "movie name",
                         "front_image_path" => "https://#{stash_url}/movie/3/frontimage?1234" }, "scene_index" => nil
          }] }
      end

      it "updates the movie to the scene" do
        expect(call).to eq(expected_response)
      end
    end

    context "when one of scene id and movie id are invalid" do
      before do
        body = {
          "errors" =>
            [
              { "message" => "FOREIGN KEY constraint failed",
                "path" => ["sceneUpdate"] }
            ],
          "data" => {
            "sceneUpdate" => nil
          }
        }.to_json

        stub_request(:post, "#{stash_url}/graphql").with do |request|
          body = JSON.parse(request.body)
          body["operationName"] == "SceneUpdate"
        end.to_return(status: 200,
                      body: body,
                      headers: { "Content-Type" => "application/json" })
      end

      it "raises an error" do
        expect { call }.to raise_error(XxxRename::Integrations::StashAPIError, /Stash API returned error/)
      end
    end
  end
end
