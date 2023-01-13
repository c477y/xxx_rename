# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/stash_db"

describe XxxRename::SiteClients::StashDb do
  describe "#setup_credentials" do
    subject(:login) { described_class.new(config).setup_credentials! }

    context "when using api token" do
      include_context "config provider" do
        let(:override_config) { { "site" => { "stash" => { "api_token" => api_token } } } }
      end

      context "successful login" do
        around do |example|
          stub = stub_request(:post, %r{https://stashdb.org/graphql})
                 .to_return(
                   status: 200,
                   body: "{\"data\":{\"version\":{\"version\":\"some_version\"}}}",
                   headers: { "content-type" => "application/json" }
                 )
          example.run
          remove_request_stub(stub)
        end

        let(:api_token) { "valid_api_token" }

        it "does not raise an exception" do
          expect { login }.not_to raise_error(XxxRename::SiteClients::Errors::UnauthorizedError)
        end

        it "returns the version" do
          expect(login).to eq("some_version")
        end
      end

      context "unsuccessful login" do
        let(:api_token) { "invalid_api_token" }

        around do |example|
          stub = stub_request(:post, %r{https://stashdb.org/graphql})
                 .to_return(
                   status: 401,
                   body: ""
                 )
          example.run
          remove_request_stub(stub)
        end

        it "raises api exception" do
          expect { login }.to raise_error(XxxRename::SiteClients::Errors::APIError)
        end
      end
    end

    context "when using username/password" do
      include_context "config provider" do
        let(:override_config) { { "site" => { "stash" => { "username" => username, "password" => password } } } }
      end

      let(:username) { "foo" }
      let(:password) { "bar" }

      context "given correct credentials" do
        before do
          stub_request(:post, "https://stashdb.org/login")
            .to_return(status: 200, body: "", headers: { "set-cookie" => cookie })
        end

        let(:cookie) { "session=session_id; Max-Age=3600" }
        it "should return a valid cookie" do
          expect(login).to eq(cookie)
        end
      end

      context "given in-correct credentials" do
        before do
          stub_request(:post, "https://stashdb.org/login").to_return(status: 401)
        end

        it "raise correct error" do
          expect { login }.to raise_error(XxxRename::SiteClients::Errors::UnauthorizedError)
        end
      end

      context "when login returns any other status code other than 200 and 401" do
        before do
          stub_request(:post, "https://stashdb.org/login").to_return(status: 500)
        end

        it "raise a runtime error" do
          expect { login }.to raise_error(XxxRename::SiteClients::Errors::InternalServerError)
        end
      end
    end
  end

  describe "#actor_details" do
    subject(:actor_details) { described_class.new(config).actor_details(name) }

    let(:name) { "Angela White" }
    context "when no credentials are provided" do
      include_context "config provider"

      it "returns immediately and does not call any APIs" do
        expect(actor_details).to be nil
      end
    end

    context "with valid credentials" do
      include_context "config provider" do
        let(:override_config) do
          { "site" => { "stash" => { "api_token" => "api_token" } } }
        end
      end

      around do |example|
        stub = stub_request(:post, %r{https://stashdb.org/graphql})
               .with(body: hash_including("operationName" => "Version"))
               .to_return(
                 status: 200, body: "{\"data\":{\"version\":{\"version\":\"some_version\"}}}",
                 headers: { "content-type" => "application/json" }
               )
        example.run
        remove_request_stub(stub)
      end

      context "when api returns a response" do
        around do |example|
          res = "{\"data\":{\"searchPerformer\":[{\"name\":\"Angela White\",\"gender\":\"FEMALE\"}]}}"
          stub = stub_request(:post, %r{https://stashdb.org/graphql})
                 .with(body: hash_including("operationName" => "SearchPerformers"))
                 .to_return(
                   status: 200, body: res,
                   headers: { "content-type" => "application/json" }
                 )
          example.run
          remove_request_stub(stub)
        end

        context "successful response" do
          let(:expected_response) { { "gender" => "FEMALE", "name" => "Angela White" } }

          it "returns the correct response" do
            expect(actor_details).to eq(expected_response)
          end
        end

        context "unsuccessful response" do
          let(:name) { "foo" }

          it "returns the correct response" do
            expect(actor_details).to be nil
          end
        end
      end
    end
  end

  describe "#search" do
    subject(:call) { described_class.new(config).search(filename) }

    include_context "config provider" do
      let(:override_config) do
        { "site" => { "stash" => { "username" => "username", "password" => "password", "file_source_format" => ["%female_actors - %title"] } } }
      end
    end

    let(:filename) { "Victoria Lobov - My Friends Hot Mom" }

    let(:search_resp) do
      { "data" =>
          { "searchScene" =>
              [{ "id" => "f82b63b2-9817-428b-8b6a-604e14382fc0",
                 "date" => "2022-03-18",
                 "title" => "Busty Blonde MILF Victoria Lobov is dying for some BIG cock",
                 "studio" => { "name" => "My Friend's Hot Mom" },
                 "performers" =>
                   [{ "as" => nil, "performer" => { "id" => "849a6458-b2be-41d1-98e3-e0a9909a2a16", "name" => "Victoria Lobov",
                                                    "gender" => "FEMALE", "aliases" => ["Arinka Kalinka"] } },
                    { "as" => nil, "performer" => { "id" => "b0fb123f-6721-49d0-ad7e-fa7aabb3e37e", "name" => "Apollo Banks",
                                                    "gender" => "MALE", "aliases" => [] } }] },
               { "id" => "820e4348-3c03-472f-adb1-765bc5badbde",
                 "date" => "2021-07-09",
                 "title" => "Sexy Blonde MILF Victoria Lobov loves young cock",
                 "studio" => { "name" => "My Friend's Hot Mom" },
                 "performers" =>
                   [{ "as" => nil, "performer" => { "id" => "849a6458-b2be-41d1-98e3-e0a9909a2a16",
                                                    "name" => "Victoria Lobov", "gender" => "FEMALE", "aliases" => ["Arinka Kalinka"] } },
                    { "as" => nil, "performer" => { "id" => "d66532b5-a426-4188-ae1e-15886e75fdaa",
                                                    "name" => "Johnny", "gender" => "MALE", "aliases" => [] } }] }] } }.to_json
    end

    let(:nil_search_resp) do
      { "data" => { "searchScene" => [] } }.to_json
    end

    let(:expected_resp) do
      XxxRename::Data::SceneData.new(
        female_actors: ["Victoria Lobov"],
        male_actors: ["Apollo Banks"],
        actors: ["Victoria Lobov", "Apollo Banks"],
        collection: "My Friend's Hot Mom",
        collection_tag: "ST",
        title: "Busty Blonde MILF Victoria Lobov is dying for some BIG cock",
        id: "f82b63b2-9817-428b-8b6a-604e14382fc0",
        date_released: Time.parse("2022-03-18")
      )
    end

    before do
      stub_request(:post, "https://stashdb.org/login").to_return(status: 200, body: "", headers: { "set-cookie": "abc" })
    end

    context "when stash db matches a scene" do
      before do
        stub_request(:post, "https://stashdb.org/graphql")
          .to_return(status: 200, body: search_resp, headers: { "content-type" => "application/json" })
      end

      it "should return scene data" do
        expect(call).to eq(expected_resp)
      end
    end

    context "when stash db is not able to match a scene" do
      before do
        stub_request(:post, "https://stashdb.org/login").to_return(status: 200, body: "", headers: { "set-cookie": "abc" })
        stub_request(:post, "https://stashdb.org/graphql")
          .to_return(status: 200, body: nil_search_resp, headers: { "content-type" => "application/json" })
      end

      it "should return scene data" do
        expect { call }.to raise_error(XxxRename::SiteClients::Errors::NoMatchError, "No results from API using query My Friends Hot Mom")
      end
    end
  end
end
