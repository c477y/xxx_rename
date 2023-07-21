# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/stash_db"

describe XxxRename::SiteClients::StashDb do
  WebMock.allow_net_connect!

  describe "#setup_credentials" do
    subject(:login) { described_class.new(config).setup_credentials! }

    context "when using api token" do
      include_context "config provider" do
        let(:override_config) { { "site" => { "stash" => { "api_token" => api_token } } } }
      end

      context "successful login" do
        before { SiteClientStubs::StashDb.enable_version_stub }

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

        before { SiteClientStubs::StashDb.enable_unauthorised_stub(%r{https://stashdb.org/graphql}) }

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
        before { SiteClientStubs::StashDb.enable_successful_username_login_stub(cookie) }

        let(:cookie) { "session=session_id; Max-Age=3600" }
        it "should return a valid cookie" do
          expect(login).to eq(cookie)
        end
      end

      context "given in-correct credentials" do
        before { SiteClientStubs::StashDb.enable_unauthorised_stub(%r{https://stashdb.org/login}) }

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

      before do
        SiteClientStubs::StashDb.enable_version_stub
        SiteClientStubs::StashDb.enable_actor_details_stub(actor_name: "Angela White", gender: "FEMALE")
      end

      context "when api returns a response" do
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
        { "site" => { "stash" => { "api_token" => api_token, "file_source_format" => ["%female_actors - %title"] } } }
      end
    end

    let(:filename) { "Victoria Lobov - My Friends Hot Mom" }

    context "when stash db matches a scene" do
      let(:api_token) do
        key = ENV.fetch("XXX_RENAME_STASH_DB_API_KEY", nil)
        if key.present?
          WebMock.disable_net_connect!(allow: "https://stashdb.org")
          ENV.fetch("XXX_RENAME_STASH_DB_API_KEY")
        else
          WebMock.disable_net_connect!
          SiteClientStubs::StashDb.enable_version_stub
          SiteClientStubs::StashDb.enable_search_scene_stub
          SiteClientStubs::StashDb.enable_scene_stub
          "api_key"
        end
      end

      let(:expected_resp) do
        XxxRename::Data::SceneData.new(
          female_actors: ["Victoria Lobov"],
          male_actors: ["Johnny The Kid"],
          actors: ["Victoria Lobov", "Johnny The Kid"],
          collection: "My Friend's Hot Mom",
          collection_tag: "ST",
          title: "Sexy Blonde MILF Victoria Lobov loves young cock",
          id: "820e4348-3c03-472f-adb1-765bc5badbde",
          date_released: Time.parse("2021-07-9"),
          scene_link: "https://www.naughtyamerica.com/scene/sexy-blonde-milf-victoria-lobov-loves-young-cock-26651",
          scene_cover: "https://cdn.stashdb.org/images/1b/db/1bdbfe63-7201-4734-a3a8-0c2ec9b7742f",
          description: "Sexy MILF Victoria Lobov gets a visit from a friend of her son's to clean their pool. " \
                        "Its a hot sunny day so she pulls her big round tits out to catch some rays. It surprises " \
                        "Johnny and out of disbelief he falls in the pool. Victoria takes him inside to make sure " \
                        "he's ok and notices his huge hard on."
        )
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

      let(:api_token) { "api_token" }
      let(:nil_search_resp) do
        { "data" => { "searchScene" => [] } }.to_json
      end

      it "should return scene data" do
        expect { call }.to raise_error(XxxRename::SiteClients::Errors::NoMatchError, "No results from API using query My Friends Hot Mom")
      end
    end
  end
end
